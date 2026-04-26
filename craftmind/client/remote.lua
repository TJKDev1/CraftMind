local PROTOCOL = "craftmind.v1"

local M = {}

local function openAnyModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then rednet.open(side); return side end
  end
  return nil
end

local function ensureModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
      if not rednet.isOpen or not rednet.isOpen(side) then rednet.open(side) end
      return side
    end
  end
  return nil, "No modem found"
end

local function request(id, msg, timeout)
  local _, err = ensureModem()
  if err then return nil, err end
  rednet.send(id, msg, PROTOCOL)
  local deadline = os.clock() + (timeout or 10)
  while os.clock() < deadline do
    local sender, res = rednet.receive(PROTOCOL, math.min(0.5, math.max(0, deadline - os.clock())))
    if sender == id then return res end
  end
  return nil, "no response"
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
      table.insert(found, { id = id, name = msg.name, safety = msg.safety, remote_auth = msg.remote_auth, turtle = msg.turtle })
    end
  end
  return found
end

function M.status(id, auth)
  return request(id, { type = "status", auth = auth }, 5)
end

function M.inventory(id, auth)
  return request(id, { type = "inventory", auth = auth }, 5)
end

function M.inspect(id, direction, auth)
  return request(id, { type = "inspect", direction = direction or "forward", auth = auth }, 5)
end

function M.select(id, slot, auth)
  return request(id, { type = "select", slot = tonumber(slot), auth = auth }, 5)
end

function M.refuel(id, count, auth)
  return request(id, { type = "refuel", count = tonumber(count) or 1, auth = auth }, 10)
end

function M.runLua(id, code, auth)
  return request(id, { type = "run_lua", code = code, auth = auth }, 30)
end

return M
