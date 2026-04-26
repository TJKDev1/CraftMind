package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local render = require("craftmind.ui.render")
local agent = require("craftmind.ai.workspace_agent")
local tools = require("craftmind.ai.workspace_tools")

settingsx.defineAll()
tools.ensureWorkspace()

local function maxSteps()
  return tonumber(settingsx.agentMaxSteps and settingsx.agentMaxSteps() or config.defaults.agentMaxSteps) or 8
end

local function canRun()
  if tools.canRun() then return true end
  render.error("Agent blocked. Set safety=power or profile=admin in Setup/settings.")
  return false
end

print("CraftMind Agent v" .. config.version)
print("Workspace: " .. tools.root())
print("Provider: " .. settingsx.provider() .. " | Model: " .. tostring(settingsx.model()))
print("Idea: OpenClaw-style agent workflows for ComputerCraft.")
print("Type /quit to exit. Agent auto-runs tool blocks.")
print("Warning: shell/Lua tools have full ComputerCraft permissions.")

while true do
  write("\nTask> ")
  local task = read()
  if task == "/quit" then break end
  if task == "/workspace" then
    print(tools.root())
  elseif task ~= "" then
    if not canRun() then
      print("Run Setup -> Power mode, or set profile=admin.")
    else
      local prior = {}
      local hitLimit = true
      local aborted = false
      for step = 1, maxSteps() do
        print("\n-- step " .. step .. " --")
        local reply, err = agent.ask(task, prior)
        if not reply then render.error(err); aborted = true; break end

        local display = tools.stripToolBlocks(reply)
        if display ~= "" then render.renderAssistant(display) end

        local ops = tools.extract(reply)
        table.insert(prior, { role = "assistant", content = reply })

        if #ops == 0 then
          hitLimit = false
          break
        end

        print("\nRunning " .. #ops .. " tool(s)...")
        local obs = tools.runAll(ops)
        print(obs)
        table.insert(prior, { role = "user", content = "Tool observations:\n" .. obs })
      end
      if hitLimit and not aborted then print("Step limit reached.") end
    end
  end
end
