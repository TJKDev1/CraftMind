local M = {}
M.path = "/craftmind/logs/latest.log"

local function ensureDir(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

function M.setPath(path) M.path = path end

function M.log(level, msg)
  ensureDir(M.path)
  local f = fs.open(M.path, "a")
  f.writeLine(os.date("%Y-%m-%d %H:%M:%S") .. " [" .. level .. "] " .. tostring(msg))
  f.close()
end

function M.info(msg) M.log("INFO", msg) end
function M.warn(msg) M.log("WARN", msg) end
function M.error(msg) M.log("ERROR", msg) end

return M
