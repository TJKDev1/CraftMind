package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local menu = require("craftmind.ui.menu")
local render = require("craftmind.ui.render")

settingsx.defineAll()

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function hasModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then return side end
  end
  return nil
end

local function hasTurtle()
  return turtle ~= nil
end

local function generateToken()
  math.randomseed(((os.epoch and os.epoch("utc")) or os.time()) + os.getComputerID())
  local parts = { "cm", tostring(os.getComputerID()) }
  for _ = 1, 4 do parts[#parts + 1] = string.format("%04x", math.random(0, 65535)) end
  return table.concat(parts, "-")
end

local function masked(token)
  token = token or ""
  if token == "" then return "missing (remote locked)" end
  if #token <= 8 then return string.rep("*", #token) end
  return string.sub(token, 1, 4) .. "..." .. string.sub(token, -4)
end

local function showCommands(token)
  print("Use same token on server + client.")
  print("")
  print("Server once:")
  print("/craftmind/turtle/server.lua --token=" .. token)
  print("")
  print("Or persist setting on each computer:")
  print("set " .. config.settings.authToken .. " " .. token)
  print("")
  print("Then start server:")
  print("/craftmind/turtle/server.lua")
end

local function setAuthToken()
  while true do
    local item = menu.choose("Auth token (current: " .. masked(settingsx.authToken()) .. ")", {
      { label = "Paste / edit token", value = "paste" },
      { label = "Generate token and save here", value = "generate" },
      { label = "Clear token (lock remote commands)", value = "clear" },
      { label = "Back", value = "back" },
    })
    if not item or item.value == "back" then return end
    if item.value == "paste" then
      local token = trim(menu.prompt("Auth token", settingsx.authToken() or "") or "")
      settingsx.set(config.settings.authToken, token)
    elseif item.value == "generate" then
      local token = generateToken()
      settingsx.set(config.settings.authToken, token)
      term.clear()
      term.setCursorPos(1, 1)
      print("Generated token saved on this computer.")
      print("Next: put same token on turtle server.")
      print("Advanced -> Manual server/client commands shows copy/paste commands.")
      menu.pause()
    elseif item.value == "clear" then
      settingsx.set(config.settings.authToken, "")
    end
  end
end

local function status()
  term.clear()
  term.setCursorPos(1, 1)
  local modem = hasModem()
  print("Turtle Channel Status")
  print("=====================")
  print("Computer ID: " .. tostring(os.getComputerID()))
  print("Label: " .. tostring(os.getComputerLabel() or ""))
  print("Role ready: " .. (hasTurtle() and "turtle server capable" or "client/server computer"))
  print("Modem: " .. tostring(modem or "missing"))
  print("Server name: " .. tostring(settingsx.serverName()))
  print("Safety: " .. tostring(settingsx.safety()))
  print("Auth: " .. masked(settingsx.authToken()))
  print("Workspace channel doc: " .. tostring(settingsx.workspace()) .. "/.craftmind/channels.md")
  print("")
  print("OpenClaw-style flow:")
  print("1) Configure same auth token on client + turtle server.")
  print("2) Start server on turtle/computer with modem.")
  print("3) Discover remote. Inspect status before actions.")
  print("4) Raw Lua still needs server safety=power + confirmation.")
  print("")
  if not modem then render.error("Attach wired/wireless modem before rednet use.") end
  if (settingsx.authToken() or "") == "" then render.error("Auth token missing. Remote commands stay locked.") end
  menu.pause()
end

local function serverName()
  local name = trim(menu.prompt("Turtle server name", settingsx.serverName() or config.defaults.serverName) or "")
  if name == "" then name = config.defaults.serverName end
  settingsx.set(config.settings.serverName, name)
end

local function startServer()
  shell.run("/craftmind/turtle/server.lua")
end

local function remoteConsole()
  shell.run("/craftmind/apps/remote.lua")
end

local function manualCommands()
  term.clear()
  term.setCursorPos(1, 1)
  local token = settingsx.authToken() or ""
  if token == "" then
    print("No token set. Generate or paste token first.")
  else
    showCommands(token)
  end
  menu.pause()
end

local function advancedMenu()
  while true do
    local choice = menu.choose("Turtle Channel Advanced", {
      { label = "Start turtle server on this computer", run = startServer },
      { label = "Set turtle server name", run = serverName },
      { label = "Manual server/client commands", run = manualCommands },
      { label = "Run advanced onboarding", run = function() shell.run("/craftmind/apps/setup.lua --advanced") end },
      { label = "Back", run = function() return "back" end },
    })
    if not choice then return end
    local result = choice.run()
    if result == "back" then return end
  end
end

while true do
  local auth = settingsx.authToken() or ""
  local modem = hasModem()
  local title = "CraftMind Turtle Channel v" .. config.version .. " [auth=" .. (auth == "" and "missing" or "set") .. ", modem=" .. tostring(modem or "missing") .. "]"
  local choice = menu.choose(title, {
    { label = "Set / generate auth token", run = setAuthToken },
    { label = "Discover / control remote turtles", run = remoteConsole },
    { label = "Channel status / next steps", run = status },
    { label = "Advanced server/manual setup", run = advancedMenu },
    { label = "Exit", run = function() return "exit" end },
  })
  if not choice then break end
  local result = choice.run()
  if result == "exit" then break end
end
