package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local menu = require("craftmind.ui.menu")
local render = require("craftmind.ui.render")
local identity = require("craftmind.identity")
local chat = require("craftmind.ai.chat")
local orchestrator = require("craftmind.ai.orchestrator")

settingsx.defineAll()
identity.ensureAgent(identity.defaultAgentId())

local function listAgents()
  print("Agents:")
  local active = identity.defaultAgentId()
  for _, id in ipairs(identity.listAgents()) do
    print((id == active and "* " or "  ") .. id .. " -> .craftmind/agents/" .. id)
  end
end

local function hatch()
  term.clear()
  term.setCursorPos(1, 1)
  print("CraftMind Hatch")
  print("===============")
  local id = identity.sanitizeId(menu.prompt("Agent id", "main"))
  local name = menu.prompt("Name", id)
  print("Give this ComputerCraft agent a soul/personality.")
  print("Keep it about Lua, turtles, rednet, terminal UX, and workspace safety.")
  local soul = menu.prompt("Soul", "A curious ComputerCraft agent who builds safe turtle and Lua systems.")
  local hatched, err = identity.hatch(id, name, soul)
  if not hatched and tostring(err):find("already exists", 1, true) then
    identity.rehatch(id, name, soul)
    print("Agent updated and activated: " .. id)
  elseif not hatched then
    render.error(err)
  else
    print("Hatched " .. hatched .. " at .craftmind/agents/" .. hatched)
  end
  menu.pause()
end

local function talk()
  local id = identity.sanitizeId(menu.prompt("Talk to agent", identity.defaultAgentId()))
  identity.ensureAgent(id)
  identity.setDefaultAgent(id)
  local history = {}
  print("Talking to " .. id .. ". Type /back to return.")
  while true do
    write("\nYou> ")
    local input = read()
    if input == "/back" or input == "/quit" then break end
    if input ~= "" then
      local reply, err = chat.ask(history, input, { agentId = id })
      if not reply then
        render.error(err)
      else
        render.renderAssistant(reply)
        table.insert(history, { role = "user", content = input })
        table.insert(history, { role = "assistant", content = reply })
        while #history > 12 do table.remove(history, 1) end
      end
    end
  end
end

local function agentMessage()
  local fromId = identity.sanitizeId(menu.prompt("From agent", identity.defaultAgentId()))
  local toId = identity.sanitizeId(menu.prompt("To agent", "main"))
  identity.ensureAgent(fromId)
  identity.ensureAgent(toId)
  print("Message from " .. fromId .. " to " .. toId .. ":")
  local msg = read()
  local ok, res = orchestrator.sendMessage(fromId, toId, msg)
  if ok then
    print(res)
  else
    render.error(res)
  end
  menu.pause()
end

while true do
  local choice = menu.choose("CraftMind Agents v" .. config.version, {
    { label = "List agents", run = function() term.clear(); term.setCursorPos(1, 1); listAgents(); menu.pause() end },
    { label = "Hatch / activate agent", run = hatch },
    { label = "Talk to active agent", run = talk },
    { label = "Agent-to-agent message", run = agentMessage },
    { label = "Open Agent Workspace", run = function() shell.run("/craftmind/apps/agent.lua") end },
    { label = "Exit", run = function() return "exit" end },
  })
  if not choice then break end
  local result = choice.run()
  if result == "exit" then break end
end
