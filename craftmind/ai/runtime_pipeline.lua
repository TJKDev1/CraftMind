local providers = require("craftmind.providers")
local config = require("craftmind.config")
local settingsx = require("craftmind.core.settings")
local identity = require("craftmind.identity")
local session = require("craftmind.ai.session")
local workspaceAgent = require("craftmind.ai.workspace_agent")
local tools = require("craftmind.ai.workspace_tools")

local M = {}

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copyList(list)
  local out = {}
  for _, item in ipairs(list or {}) do out[#out + 1] = item end
  return out
end

local function defaultMaxSteps()
  return tonumber(settingsx.agentMaxSteps and settingsx.agentMaxSteps() or config.defaults.agentMaxSteps) or 8
end

local INTERNAL_OPTS = {
  agentId = true,
  channel = true,
  from = true,
  historyLimit = true,
  maxSteps = true,
  modelFn = true,
  noRunTools = true,
  persist = true,
  sessionId = true,
  taskInPrior = true,
  onStep = true,
  onContext = true,
  onAssistant = true,
  onTools = true,
  onObservation = true,
  onPersist = true,
}

local function providerOptions(opts)
  local out = {}
  for k, v in pairs(opts or {}) do
    if not INTERNAL_OPTS[k] then out[k] = v end
  end
  return out
end

local function sessionFor(channel, agentId)
  channel = trim(channel or "terminal")
  if channel == "" then channel = "terminal" end
  return channel .. "-" .. agentId
end

function M.channel(input, opts)
  opts = opts or {}
  local envelope = {}
  if type(input) == "table" then
    for k, v in pairs(input) do envelope[k] = v end
  else
    envelope.text = tostring(input or "")
  end
  envelope.channel = trim(envelope.channel or opts.channel or "terminal")
  if envelope.channel == "" then envelope.channel = "terminal" end
  envelope.text = trim(envelope.text or envelope.task or envelope.message or envelope.content or "")
  envelope.agentId = envelope.agentId or opts.agentId
  envelope.sessionId = envelope.sessionId or opts.sessionId
  envelope.from = envelope.from or opts.from or envelope.channel
  return envelope
end

function M.route(envelope, opts)
  opts = opts or {}
  envelope = M.channel(envelope, opts)
  local agentId = identity.sanitizeId(envelope.agentId or identity.defaultAgentId())
  identity.ensureAgent(agentId)
  local sessionId = trim(envelope.sessionId or sessionFor(envelope.channel, agentId))
  local historyLimit = tonumber(envelope.historyLimit or opts.historyLimit) or 12
  return {
    channel = envelope.channel,
    from = envelope.from,
    agentId = agentId,
    sessionId = sessionId,
    task = envelope.text,
    prior = session.recent(sessionId, historyLimit),
    historyLimit = historyLimit,
  }
end

function M.context(route, prior, opts)
  opts = opts or {}
  local ctx = {
    route = route,
    prior = copyList(prior or route.prior),
  }
  ctx.messages = workspaceAgent.buildMessages(route.task, ctx.prior, {
    agentId = route.agentId,
    taskInPrior = opts.taskInPrior == true,
  })
  if opts.onContext then opts.onContext(ctx) end
  return ctx
end

function M.model(ctx, opts)
  opts = opts or {}
  local reply, err
  if opts.modelFn then
    reply, err = opts.modelFn(ctx)
  else
    reply, err = providers.chat(ctx.messages, providerOptions(opts))
  end
  return {
    context = ctx,
    reply = reply,
    err = err,
    ok = reply ~= nil,
  }
end

function M.tools(modelResult, opts)
  opts = opts or {}
  if not modelResult.ok then
    return {
      model = modelResult,
      ok = false,
      err = modelResult.err,
      reply = modelResult.reply,
      display = "",
      ops = {},
      observation = nil,
    }
  end

  local reply = tostring(modelResult.reply or "")
  local display = tools.stripToolBlocks(reply)
  if display ~= "" and opts.onAssistant then opts.onAssistant(display, reply, modelResult) end

  local ops = tools.extract(reply)
  local observation = nil
  if #ops > 0 then
    if opts.onTools then opts.onTools(ops, modelResult) end
    if opts.noRunTools then
      observation = "Tool execution skipped."
    else
      observation = tools.runAll(ops)
    end
    if opts.onObservation then opts.onObservation(observation, ops, modelResult) end
  end

  return {
    model = modelResult,
    ok = true,
    reply = reply,
    display = display,
    ops = ops,
    observation = observation,
  }
end

function M.persist(toolResult, opts)
  opts = opts or {}
  local ctx = toolResult.model and toolResult.model.context or nil
  local route = ctx and ctx.route or nil
  if not route then return false, "missing route" end
  if opts.persist == false then return true end

  local ok, err
  if opts.persistUser then
    ok, err = session.append(route.sessionId, "user", route.task)
    if not ok then return false, err end
  end
  if toolResult.ok and toolResult.reply then
    ok, err = session.append(route.sessionId, "assistant", toolResult.reply)
    if not ok then return false, err end
  end
  if toolResult.observation then
    ok, err = session.append(route.sessionId, "user", "Tool observations:\n" .. toolResult.observation)
    if not ok then return false, err end
  end
  if opts.onPersist then opts.onPersist(toolResult, route) end
  return true
end

function M.step(route, prior, stepIndex, opts)
  opts = opts or {}
  if opts.onStep then opts.onStep(stepIndex, route) end
  local ctx = M.context(route, prior, { taskInPrior = true, onContext = opts.onContext })
  local modelResult = M.model(ctx, opts)
  local toolResult = M.tools(modelResult, opts)
  local persistOk, persistErr = M.persist(toolResult, {
    persist = opts.persist,
    persistUser = opts.persistUser,
    onPersist = opts.onPersist,
  })
  toolResult.persistOk = persistOk
  toolResult.persistErr = persistErr
  toolResult.step = stepIndex
  return toolResult
end

function M.run(input, opts)
  opts = opts or {}
  local envelope = M.channel(input, opts)
  if envelope.text == "" then return false, "empty task" end

  local route = M.route(envelope, opts)
  local prior = copyList(route.prior)
  prior[#prior + 1] = { role = "user", content = route.task }

  local maxSteps = tonumber(opts.maxSteps) or defaultMaxSteps()
  local result = {
    route = route,
    steps = {},
    hitLimit = true,
    ok = true,
  }

  local persistUser = true
  for stepIndex = 1, maxSteps do
    local stepOpts = {}
    for k, v in pairs(opts) do stepOpts[k] = v end
    stepOpts.persistUser = persistUser
    local step = M.step(route, prior, stepIndex, stepOpts)
    persistUser = false
    result.steps[#result.steps + 1] = step

    if not step.ok then
      result.ok = false
      result.err = step.err
      result.hitLimit = false
      return false, step.err, result
    end
    if not step.persistOk then
      result.ok = false
      result.err = step.persistErr
      result.hitLimit = false
      return false, step.persistErr, result
    end

    prior[#prior + 1] = { role = "assistant", content = step.reply }
    if step.observation then prior[#prior + 1] = { role = "user", content = "Tool observations:\n" .. step.observation } end

    if #step.ops == 0 then
      result.hitLimit = false
      return true, result
    end
  end

  return true, result
end

return M
