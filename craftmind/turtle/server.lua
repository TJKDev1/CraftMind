package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local luaAgent = require("craftmind.ai.lua_agent")
local logger = require("craftmind.core.logger")
local config = require("craftmind.config")

settingsx.defineAll()

local PROTOCOL = "craftmind.v1"
local startedAt = os.clock()
local requestCount = 0
local modemSide = nil

local function parseArgs(argv)
  local out = {}
  for _, arg in ipairs(argv or {}) do
    local key, value = tostring(arg):match("^%-%-([^=]+)=(.*)$")
    if key then
      out[key:gsub("%-", "_")] = value
    else
      key = tostring(arg):match("^%-%-([^=]+)$")
      if key then out[key:gsub("%-", "_")] = true end
    end
  end
  return out
end

local function generateToken()
  math.randomseed(((os.epoch and os.epoch("utc")) or os.time()) + os.getComputerID())
  local parts = { "cm", tostring(os.getComputerID()) }
  for _ = 1, 4 do parts[#parts + 1] = string.format("%04x", math.random(0, 65535)) end
  return table.concat(parts, "-")
end

local args = parseArgs({ ... })
if args.name and args.name ~= "" then settingsx.set(config.settings.serverName, args.name) end
if args.token and args.token ~= "" then settingsx.set(config.settings.authToken, args.token) end
if args.generate_token then
  local token = generateToken()
  settingsx.set(config.settings.authToken, token)
  print("Generated auth token: " .. token)
  print("Copy same token to CraftMind Turtle Channel on client.")
end

local function openAnyModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
      if not rednet.isOpen or not rednet.isOpen(side) then rednet.open(side) end
      return side
    end
  end
  return nil
end

local function hasTurtle()
  return turtle ~= nil
end

local function authToken()
  return settingsx.authToken() or ""
end

local function allowed(msg)
  local token = authToken()
  if token == "" then return false end
  return msg and msg.auth == token
end

local function authError()
  if authToken() == "" then
    return {
      type = "error",
      code = "locked",
      error = "server locked: set craftmind.auth_token on server and client",
      remote_auth = settingsx.remoteAuthStatus(),
    }
  end
  return {
    type = "error",
    code = "unauthorized",
    error = "unauthorized: auth token mismatch or missing",
    remote_auth = settingsx.remoteAuthStatus(),
  }
end

local function basePayload(kind)
  return {
    type = kind,
    name = settingsx.serverName(),
    label = os.getComputerLabel(),
    id = os.getComputerID(),
    safety = settingsx.safety(),
    remote_auth = settingsx.remoteAuthStatus(),
    turtle = hasTurtle(),
    uptime = math.floor(os.clock() - startedAt),
    requests = requestCount,
  }
end

local function statusPayload()
  local payload = basePayload("status_result")
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

local function discoverPayload()
  local payload = basePayload("discover_result")
  payload.modem = modemSide
  return payload
end

local function handle(msg)
  if msg.type == "discover" then return discoverPayload() end
  if not allowed(msg) then return authError() end
  if msg.type == "run_lua" then
    local ok, result = luaAgent.run(msg.code or "", { confirm = true })
    return { type = "run_lua_result", ok = ok, result = tostring(result) }
  elseif msg.type == "status" then
    return statusPayload()
  elseif msg.type == "inventory" then
    return inventoryPayload()
  elseif msg.type == "inspect" then
    return inspectPayload(msg.direction)
  elseif msg.type == "select" then
    return selectPayload(msg.slot)
  elseif msg.type == "refuel" then
    return refuelPayload(msg.count)
  end
  return { type = "error", error = "unknown message type: " .. tostring(msg.type) }
end

local function printStartup(side)
  term.clear()
  term.setCursorPos(1, 1)
  print("CraftMind Turtle Server")
  print("=======================")
  print("Name: " .. tostring(settingsx.serverName()))
  print("Computer ID: " .. tostring(os.getComputerID()))
  print("Label: " .. tostring(os.getComputerLabel() or ""))
  print("Modem: " .. tostring(side))
  print("Protocol: " .. PROTOCOL)
  print("Turtle APIs: " .. tostring(hasTurtle()))
  print("Safety: " .. tostring(settingsx.safety()))
  print("Remote auth: " .. tostring(settingsx.remoteAuthStatus()))
  print("")
  if authToken() == "" then
    print("Remote commands locked: no auth token set.")
    print("Set token with Turtle Channel app or:")
    print("/craftmind/turtle/server.lua --token=<token>")
  else
    print("Remote commands require matching auth token.")
  end
  print("")
  print("OpenClaw flow: discover -> status -> inspect -> act.")
  print("Press Ctrl+T to stop server.")
  print("")
end

local side = openAnyModem()
modemSide = side
if not side then
  print("CraftMind Turtle Server")
  print("=======================")
  print("No modem found.")
  print("Attach wired/wireless modem, then run:")
  print("/craftmind/turtle/server.lua")
  print("")
  print("Optional first setup:")
  print("/craftmind/apps/turtle.lua")
  return
end

printStartup(side)
logger.info("Turtle server started")

while true do
  local sender, msg = rednet.receive(PROTOCOL)
  if type(msg) == "table" then
    requestCount = requestCount + 1
    local res = handle(msg)
    rednet.send(sender, res, PROTOCOL)
    print("#" .. tostring(requestCount) .. " from " .. tostring(sender) .. " " .. tostring(msg.type) .. " -> " .. tostring(res.type) .. (res.code and ("/" .. tostring(res.code)) or ""))
  end
end
