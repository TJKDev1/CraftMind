package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local render = require("craftmind.ui.render")
local agent = require("craftmind.ai.workspace_agent")
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
    local sessionId = "terminal-" .. activeAgent
    local prior = session.recent(sessionId, 12)
    table.insert(prior, { role = "user", content = task })
    session.append(sessionId, "user", task)
    local hitLimit = true
    local aborted = false
    for step = 1, maxSteps() do
      print("\n-- step " .. step .. " --")
      local reply, err = agent.ask(task, prior, { agentId = activeAgent, taskInPrior = true })
      if not reply then render.error(err); aborted = true; break end

      local display = tools.stripToolBlocks(reply)
      if display ~= "" then render.renderAssistant(display) end

      local ops = tools.extract(reply)
      table.insert(prior, { role = "assistant", content = reply })
      session.append(sessionId, "assistant", reply)

      if #ops == 0 then
        hitLimit = false
        break
      end

      print("\nRunning " .. #ops .. " tool(s)...")
      local obs = tools.runAll(ops)
      print(obs)
      table.insert(prior, { role = "user", content = "Tool observations:\n" .. obs })
      session.append(sessionId, "user", "Tool observations:\n" .. obs)
    end
    if hitLimit and not aborted then print("Step limit reached.") end
  end
end
