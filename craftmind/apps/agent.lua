package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local render = require("craftmind.ui.render")
local pipeline = require("craftmind.ai.runtime_pipeline")
local tools = require("craftmind.ai.workspace_tools")
local identity = require("craftmind.identity")
local session = require("craftmind.ai.session")

settingsx.defineAll()
tools.ensureWorkspace()
local activeAgent = identity.defaultAgentId()
identity.ensureAgent(activeAgent)

local function maxSteps()
  return tonumber(settingsx.agentMaxSteps and settingsx.agentMaxSteps() or config.defaults.agentMaxSteps) or 8
end

print("CraftMind Agent v" .. config.version)
print("Agent: " .. activeAgent .. " (identity: .craftmind/agents/" .. activeAgent .. ")")
print("Workspace: " .. tools.root())
print("Provider: " .. settingsx.provider() .. " | Model: " .. tostring(settingsx.model()))
print("Idea: OpenClaw-style agent workflows for ComputerCraft.")
print("Type /quit to exit. /agent <id> switches. /agents lists. /session shows log. Agent auto-runs tool blocks.")
if tools.canRun() then
  print("Warning: shell/Lua tools have full ComputerCraft permissions.")
else
  print("Safe mode: file/list/read/message tools work; shell/Lua tools are blocked until safety=power or profile=admin.")
end

while true do
  write("\nTask> ")
  local task = read()
  if task == "/quit" then break end
  if task == "/workspace" then
    print(tools.root())
  elseif task == "/session" then
    print(session.path("terminal-" .. activeAgent))
  elseif task == "/agents" then
    for _, id in ipairs(identity.listAgents()) do print((id == activeAgent and "* " or "  ") .. id) end
  elseif task:sub(1, 7) == "/agent " then
    local id = identity.sanitizeId(task:sub(8))
    identity.ensureAgent(id)
    activeAgent = id
    identity.setDefaultAgent(id)
    print("Active agent: " .. activeAgent)
  elseif task ~= "" then
    local ok, errOrResult, result = pipeline.run(task, {
      agentId = activeAgent,
      sessionId = "terminal-" .. activeAgent,
      maxSteps = maxSteps(),
      onStep = function(step) print("\n-- step " .. step .. " --") end,
      onAssistant = function(display) render.renderAssistant(display) end,
      onTools = function(ops) print("\nRunning " .. #ops .. " tool(s)...") end,
      onObservation = function(obs) print(obs) end,
    })
    if not ok then render.error(errOrResult) end
    result = ok and errOrResult or result
    if result and result.hitLimit then print("Step limit reached.") end
  end
end
