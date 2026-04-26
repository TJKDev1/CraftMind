local M = {}

local function ensureParent(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

function M.read(path)
  if not fs.exists(path) then return nil, "not found: " .. tostring(path) end
  local f = fs.open(path, "r")
  local text = f.readAll()
  f.close()
  return text
end

function M.write(path, content)
  ensureParent(path)
  local f = fs.open(path, "w")
  f.write(content or "")
  f.close()
  return true
end

function M.append(path, content)
  ensureParent(path)
  local f = fs.open(path, "a")
  f.write(content or "")
  f.close()
  return true
end

function M.list(path)
  return fs.list(path or "/")
end

return M
