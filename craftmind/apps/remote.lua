package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local menu = require("craftmind.ui.menu")
local render = require("craftmind.ui.render")
local remote = require("craftmind.client.remote")

settingsx.defineAll()

local target = nil
local auth = settingsx.authToken() or ""

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function generateToken()
  math.randomseed(((os.epoch and os.epoch("utc")) or os.time()) + os.getComputerID())
  local parts = { "cm", tostring(os.getComputerID()) }
  for _ = 1, 4 do parts[#parts + 1] = string.format("%04x", math.random(0, 65535)) end
  return table.concat(parts, "-")
end

local function masked(token)
  token = token or ""
  if token == "" then return "missing" end
  if #token <= 8 then return string.rep("*", #token) end
  return string.sub(token, 1, 4) .. "..." .. string.sub(token, -4)
end

local function showTable(value)
  if textutils and textutils.serialize then print(textutils.serialize(value)) else print(tostring(value)) end
end

local function showTokenHelp(token)
  print("Same auth token must exist on client + turtle server.")
  print("")
  print("On server turtle, run one:")
  print("/craftmind/turtle/server.lua --token=" .. token)
  print("")
  print("Or persist token on server:")
  print("set " .. config.settings.authToken .. " " .. token)
  print("/craftmind/turtle/server.lua")
end

local function setAuth()
  while true do
    local item = menu.choose("Remote auth token (current: " .. masked(auth) .. ")", {
      { label = "Paste / edit token", value = "paste" },
      { label = "Generate token and save here", value = "generate" },
      { label = "Clear token", value = "clear" },
      { label = "Show server setup commands", value = "help" },
      { label = "Back", value = "back" },
    })
    if not item or item.value == "back" then return end
    if item.value == "paste" then
      auth = trim(menu.prompt("Auth token", auth or "") or "")
      settingsx.set(config.settings.authToken, auth)
    elseif item.value == "generate" then
      auth = generateToken()
      settingsx.set(config.settings.authToken, auth)
      term.clear()
      term.setCursorPos(1, 1)
      print("Generated token saved on this client.")
      print("")
      showTokenHelp(auth)
      menu.pause()
    elseif item.value == "clear" then
      auth = ""
      settingsx.set(config.settings.authToken, "")
    elseif item.value == "help" then
      term.clear()
      term.setCursorPos(1, 1)
      if auth == "" then print("No token set. Paste or generate first.") else showTokenHelp(auth) end
      menu.pause()
    end
  end
end

local function targetLabel(item)
  local label = tostring(item.id) .. " - " .. tostring(item.name or "unnamed")
  if item.label and item.label ~= "" then label = label .. " (" .. tostring(item.label) .. ")" end
  label = label .. " [safety=" .. tostring(item.safety) .. ", auth=" .. tostring(item.remote_auth or "locked") .. "]"
  if item.turtle then label = label .. " turtle" else label = label .. " computer" end
  return label
end

local function discover()
  term.clear()
  term.setCursorPos(1, 1)
  print("Discovering CraftMind turtle servers...")
  print("Protocol: craftmind.v1")
  local found, err = remote.discover(3)
  if not found then render.error(err); menu.pause(); return end
  if #found == 0 then print("No servers found. Check modem + start /craftmind/turtle/server.lua."); menu.pause(); return end
  local items = {}
  for _, item in ipairs(found) do items[#items + 1] = { label = targetLabel(item), value = item } end
  local picked = menu.choose("Select remote", items)
  if picked then target = picked.value end
end

local function requireTarget()
  if not target then discover() end
  return target ~= nil
end

local function authHint(res)
  if type(res) == "table" and res.type == "error" and (res.code == "locked" or res.code == "unauthorized") then
    print("")
    print("Auth fix:")
    print("1) Open Turtle Channel -> Set/generate auth token on client.")
    print("2) Put same token on server turtle.")
    print("3) Restart /craftmind/turtle/server.lua.")
  end
end

local function request(label, fn, presenter)
  if not requireTarget() then return end
  term.clear()
  term.setCursorPos(1, 1)
  print(label .. " -> " .. tostring(target.id))
  print(string.rep("=", #label + #tostring(target.id) + 4))
  if auth == "" then print("Warning: no auth token set on client.") end
  local res, err = fn(target.id)
  if not res then
    render.error(err)
  elseif type(res) == "table" and res.type == "error" then
    render.error(res.error or "remote error")
    authHint(res)
  elseif presenter then
    presenter(res)
  else
    showTable(res)
  end
  menu.pause()
end

local function showStatusPayload(res)
  print("Name: " .. tostring(res.name or target.name or ""))
  print("ID: " .. tostring(res.id or target.id))
  print("Label: " .. tostring(res.label or ""))
  print("Turtle: " .. tostring(res.turtle))
  print("Safety: " .. tostring(res.safety))
  print("Auth: " .. tostring(res.remote_auth))
  print("Uptime: " .. tostring(res.uptime or "?") .. "s")
  print("Requests: " .. tostring(res.requests or "?"))
  if res.turtle then
    print("Fuel: " .. tostring(res.fuel) .. " / " .. tostring(res.fuelLimit or "?"))
    print("Selected slot: " .. tostring(res.selected))
  end
end

local function showInventoryPayload(res)
  print("Selected slot: " .. tostring(res.selected))
  print("Slot | Count | Space | Item")
  print("-----+-------+-------+----------------")
  for _, slot in ipairs(res.slots or {}) do
    local name = ""
    if slot.detail and slot.detail.name then name = slot.detail.name end
    local mark = slot.slot == res.selected and ">" or " "
    print(mark .. string.format("%2d", slot.slot) .. "  | " .. string.format("%5d", slot.count or 0) .. " | " .. string.format("%5d", slot.space or 0) .. " | " .. name)
  end
end

local function showInspectPayload(res)
  print("Direction: " .. tostring(res.direction))
  print("Block found: " .. tostring(res.ok))
  if res.data then showTable(res.data) end
end

local function showStatus()
  request("Status", function(id) return remote.status(id, auth) end, showStatusPayload)
end

local function showInventory()
  request("Inventory", function(id) return remote.inventory(id, auth) end, showInventoryPayload)
end

local function inspectBlock()
  if not requireTarget() then return end
  local item = menu.choose("Inspect direction", {
    { label = "Forward", value = "forward" },
    { label = "Up", value = "up" },
    { label = "Down", value = "down" },
  })
  if item then request("Inspect " .. item.value, function(id) return remote.inspect(id, item.value, auth) end, showInspectPayload) end
end

local function selectSlot()
  if not requireTarget() then return end
  local slot = tonumber(menu.prompt("Slot 1..16", "1"))
  request("Select slot", function(id) return remote.select(id, slot, auth) end)
end

local function refuel()
  if not requireTarget() then return end
  local count = tonumber(menu.prompt("Items to consume", "1")) or 1
  request("Refuel", function(id) return remote.refuel(id, count, auth) end)
end

local function runLua()
  if not requireTarget() then return end
  term.clear()
  term.setCursorPos(1, 1)
  print("Remote raw Lua")
  print("==============")
  print("Server must have safety=power. Server will preview/confirm.")
  print("Enter one line of Lua, or blank to cancel:")
  local code = read()
  if not code or code == "" then return end
  request("Run Lua", function(id) return remote.runLua(id, code, auth) end)
end

while true do
  local current = target and (tostring(target.id) .. " " .. tostring(target.name or "")) or "none"
  local choice = menu.choose("CraftMind Remote Turtles v" .. config.version .. " [target=" .. current .. ", auth=" .. masked(auth) .. "]", {
    { label = "Set / generate auth token", run = setAuth },
    { label = "Discover/select server", run = discover },
    { label = "Status", run = showStatus },
    { label = "Inventory", run = showInventory },
    { label = "Inspect block", run = inspectBlock },
    { label = "Select slot", run = selectSlot },
    { label = "Refuel selected slot", run = refuel },
    { label = "Run remote Lua", run = runLua },
    { label = "Exit", run = function() return "exit" end },
  })
  if not choice then break end
  local result = choice.run()
  if result == "exit" then break end
end
