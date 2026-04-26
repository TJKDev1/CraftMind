package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local menu = require("craftmind.ui.menu")
local config = require("craftmind.config")

settingsx.defineAll()

if not settingsx.onboardingCompleted() then
  local firstRun = menu.choose("CraftMind first run", {
    { label = "Run OpenClaw-style onboarding", value = "run" },
    { label = "Skip for now", value = "skip" },
  })
  if firstRun and firstRun.value == "run" then shell.run("/craftmind/apps/setup.lua") end
end

while true do
  local choice = menu.choose("CraftMind v" .. config.version, {
    { label = "Agents / Hatch", run = function() shell.run("/craftmind/apps/agents.lua") end },
    { label = "Chat", run = function() shell.run("/craftmind/apps/chat.lua") end },
    { label = "Agent Workspace", run = function() shell.run("/craftmind/apps/agent.lua") end },
    { label = "Remote Turtles", run = function() shell.run("/craftmind/apps/remote.lua") end },
    { label = "Onboarding / Setup", run = function() shell.run("/craftmind/apps/setup.lua") end },
    { label = "Turtle Server", run = function() shell.run("/craftmind/turtle/server.lua") end },
    { label = "Exit", run = function() return "exit" end },
  })
  if not choice then break end
  local result = choice.run()
  if result == "exit" then break end
end
