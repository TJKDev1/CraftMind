package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local luaAgent = require("craftmind.ai.lua_agent")
local logger = require("craftmind.core.logger")

settingsx.defineAll()

local PROTOCOL = "craftmind.v1"
local SERVER_NAME = settingsx.serverName()
local AUTH_TOKEN = settingsx.authToken()

local function openAnyModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
      rednet.open(side)
      return side
    end
  end
  return nil
end

local function allowed(msg)
  if AUTH_TOKEN == "" then return false end
  return msg and msg.auth == AUTH_TOKEN
end

local function hasTurtle()
  return turtle ~= nil
end

local function statusPayload()
  local payload = {
    type = "status_result",
    label = os.getComputerLabel(),
    id = os.getComputerID(),
    safety = settingsx.safety(),
    remote_auth = settingsx.remoteAuthStatus(),
    turtle = hasTurtle(),
  }
  if hasTurtle() then
    payload.fuel = turtle.getFuelLevel()
    payload.fuelLimit = turtle.getFuelLimit and turtle.getFuelLimit() or nil
    payload.selected = turtle.getSelectedSlot()
  end
  return payload
end

local function inventoryPayload()
  if not hasTurtle() then return { type = "error", error = "not a turtle" } end
  local slots = {}
  for slot = 1, 16 do
    local detail = turtle.getItemDetail(slot)
    slots[#slots + 1] = { slot = slot, count = turtle.getItemCount(slot), space = turtle.getItemSpace(slot), detail = detail }
  end
  return { type = "inventory_result", selected = turtle.getSelectedSlot(), slots = slots }
end

local function inspectPayload(direction)
  if not hasTurtle() then return { type = "error", error = "not a turtle" } end
  local ok, data
  if direction == "up" then ok, data = turtle.inspectUp()
  elseif direction == "down" then ok, data = turtle.inspectDown()
  else ok, data = turtle.inspect() end
  return { type = "inspect_result", ok = ok, data = data, direction = direction or "forward" }
end

local function selectPayload(slot)
  if not hasTurtle() then return { type = "error", error = "not a turtle" } end
  slot = tonumber(slot)
  if not slot or slot < 1 or slot > 16 then return { type = "error", error = "slot must be 1..16" } end
  local ok, err = turtle.select(slot)
  if not ok then return { type = "error", error = tostring(err) } end
  return { type = "select_result", ok = true, selected = turtle.getSelectedSlot() }
end

local function refuelPayload(count)
  if not hasTurtle() then return { type = "error", error = "not a turtle" } end
  count = tonumber(count) or 1
  if count < 1 then return { type = "error", error = "count must be >= 1" } end
  local ok, err = turtle.refuel(count)
  return { type = "refuel_result", ok = ok, error = err, fuel = turtle.getFuelLevel() }
end

local side = openAnyModem()
if not side then error("No modem found") end

print("CraftMind turtle server online: " .. SERVER_NAME)
print("Modem: " .. side .. " | Protocol: " .. PROTOCOL)
if AUTH_TOKEN == "" then
  print("No auth token set: remote commands blocked except discover.")
else
  print("Remote commands require matching auth token.")
end
logger.info("Turtle server started")

while true do
  local sender, msg = rednet.receive(PROTOCOL)
  if type(msg) == "table" then
    if msg.type == "discover" then
      rednet.send(sender, { type = "discover_result", name = SERVER_NAME, id = os.getComputerID(), safety = settingsx.safety(), remote_auth = settingsx.remoteAuthStatus(), turtle = hasTurtle() }, PROTOCOL)
    elseif not allowed(msg) then
      rednet.send(sender, { type = "error", error = "unauthorized" }, PROTOCOL)
    elseif msg.type == "run_lua" then
      local ok, result = luaAgent.run(msg.code or "", { confirm = true })
      rednet.send(sender, { type = "run_lua_result", ok = ok, result = tostring(result) }, PROTOCOL)
    elseif msg.type == "status" then
      rednet.send(sender, statusPayload(), PROTOCOL)
    elseif msg.type == "inventory" then
      rednet.send(sender, inventoryPayload(), PROTOCOL)
    elseif msg.type == "inspect" then
      rednet.send(sender, inspectPayload(msg.direction), PROTOCOL)
    elseif msg.type == "select" then
      rednet.send(sender, selectPayload(msg.slot), PROTOCOL)
    elseif msg.type == "refuel" then
      rednet.send(sender, refuelPayload(msg.count), PROTOCOL)
    else
      rednet.send(sender, { type = "error", error = "unknown message type" }, PROTOCOL)
    end
  end
end
