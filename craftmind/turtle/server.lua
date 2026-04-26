local settingsx = require("craftmind.core.settings")
local luaAgent = require("craftmind.ai.lua_agent")
local logger = require("craftmind.core.logger")

settingsx.defineAll()

local PROTOCOL = "craftmind.v1"
local SERVER_NAME = settings.get("craftmind.server_name") or "CraftMind Turtle"
local AUTH_TOKEN = settings.get("craftmind.auth_token") or ""

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
  if AUTH_TOKEN == "" then return settingsx.profile() ~= "multiplayer" end
  return msg and msg.auth == AUTH_TOKEN
end

local side = openAnyModem()
if not side then error("No modem found") end

print("CraftMind turtle server online: " .. SERVER_NAME)
print("Modem: " .. side .. " | Protocol: " .. PROTOCOL)
logger.info("Turtle server started")

while true do
  local sender, msg = rednet.receive(PROTOCOL)
  if type(msg) == "table" then
    if msg.type == "discover" then
      rednet.send(sender, { type = "discover_result", name = SERVER_NAME, id = os.getComputerID(), safety = settingsx.safety(), profile = settingsx.profile() }, PROTOCOL)
    elseif not allowed(msg) then
      rednet.send(sender, { type = "error", error = "unauthorized" }, PROTOCOL)
    elseif msg.type == "run_lua" then
      local ok, result = luaAgent.run(msg.code or "", { confirm = true })
      rednet.send(sender, { type = "run_lua_result", ok = ok, result = tostring(result) }, PROTOCOL)
    elseif msg.type == "status" then
      rednet.send(sender, { type = "status_result", fuel = turtle and turtle.getFuelLevel() or nil, label = os.getComputerLabel() }, PROTOCOL)
    else
      rednet.send(sender, { type = "error", error = "unknown message type" }, PROTOCOL)
    end
  end
end
