local PROTOCOL = "craftmind.v1"

local M = {}

local function openAnyModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then rednet.open(side); return side end
  end
  return nil
end

function M.discover(timeout)
  local side = openAnyModem()
  if not side then return nil, "No modem found" end
  rednet.broadcast({ type = "discover" }, PROTOCOL)
  local found = {}
  local deadline = os.clock() + (timeout or 3)
  while os.clock() < deadline do
    local id, msg = rednet.receive(PROTOCOL, 0.5)
    if id and type(msg) == "table" and msg.type == "discover_result" then
      table.insert(found, { id = id, name = msg.name, safety = msg.safety, profile = msg.profile })
    end
  end
  return found
end

function M.runLua(id, code, auth)
  rednet.send(id, { type = "run_lua", code = code, auth = auth }, PROTOCOL)
  local sender, msg = rednet.receive(PROTOCOL, 30)
  if sender ~= id then return nil, "no response" end
  return msg
end

return M
