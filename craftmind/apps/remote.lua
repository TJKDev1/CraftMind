package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local menu = require("craftmind.ui.menu")
local render = require("craftmind.ui.render")
local remote = require("craftmind.client.remote")

settingsx.defineAll()

local target = nil
local auth = settingsx.authToken() or ""

local function showTable(value)
  if textutils and textutils.serialize then print(textutils.serialize(value)) else print(tostring(value)) end
end

local function discover()
  term.clear()
  term.setCursorPos(1, 1)
  print("Discovering CraftMind turtle servers...")
  local found, err = remote.discover(3)
  if not found then render.error(err); menu.pause(); return end
  if #found == 0 then print("No servers found."); menu.pause(); return end
  local items = {}
  for _, item in ipairs(found) do
    local label = tostring(item.id) .. " - " .. tostring(item.name or "unnamed") .. " [safety=" .. tostring(item.safety) .. ", remote=" .. tostring(item.remote_auth or "locked") .. "]"
    if item.turtle then label = label .. " turtle" end
    items[#items + 1] = { label = label, value = item }
  end
  local picked = menu.choose("Select remote", items)
  if picked then target = picked.value end
end

local function requireTarget()
  if not target then discover() end
  return target ~= nil
end

local function request(label, fn)
  if not requireTarget() then return end
  term.clear()
  term.setCursorPos(1, 1)
  print(label .. " -> " .. tostring(target.id))
  local res, err = fn(target.id)
  if not res then render.error(err) else showTable(res) end
  menu.pause()
end

local function showStatus()
  request("Status", function(id) return remote.status(id, auth) end)
end

local function showInventory()
  request("Inventory", function(id) return remote.inventory(id, auth) end)
end

local function inspectBlock()
  if not requireTarget() then return end
  local item = menu.choose("Inspect direction", {
    { label = "Forward", value = "forward" },
    { label = "Up", value = "up" },
    { label = "Down", value = "down" },
  })
  if item then request("Inspect " .. item.value, function(id) return remote.inspect(id, item.value, auth) end) end
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

local function setAuth()
  auth = menu.prompt("Auth token", auth or "") or ""
  settingsx.set(config.settings.authToken, auth)
end

local function runLua()
  if not requireTarget() then return end
  print("Remote raw Lua uses server-side CraftMind safety gate and confirmation.")
  print("Enter one line of Lua:")
  local code = read()
  if not code or code == "" then return end
  request("Run Lua", function(id) return remote.runLua(id, code, auth) end)
end

while true do
  local current = target and (tostring(target.id) .. " " .. tostring(target.name or "")) or "none"
  local choice = menu.choose("CraftMind Remote Turtles v" .. config.version .. " (target: " .. current .. ")", {
    { label = "Discover/select server", run = discover },
    { label = "Set auth token", run = setAuth },
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
