local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local fileTool = require("craftmind.tools.file")

local M = {}

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function now()
  if os.date then return os.date("%Y-%m-%d %H:%M:%S") end
  return tostring(os.epoch and os.epoch("utc") or os.time())
end

local function root()
  local r = settingsx.workspace and settingsx.workspace() or config.defaults.workspace
  r = trim(r or config.defaults.workspace):gsub("\\", "/")
  if r == "" or r:find("..", 1, true) then r = config.defaults.workspace end
  if not fs.exists(r) then fs.makeDir(r) end
  return r
end

local function sessionsDir()
  local dir = fs.combine(root(), ".craftmind/sessions")
  if not fs.exists(dir) then fs.makeDir(dir) end
  return dir
end

local function sanitize(id)
  id = trim(id or "terminal-main"):lower():gsub("%s+", "-"):gsub("[^%w_%-]", "")
  if id == "" then id = "terminal-main" end
  return id
end

local function pathFor(sessionId)
  return fs.combine(sessionsDir(), sanitize(sessionId) .. ".jsonl")
end

local function encode(tbl)
  if textutils and textutils.serializeJSON then return textutils.serializeJSON(tbl) end
  if textutils and textutils.serialiseJSON then return textutils.serialiseJSON(tbl) end
  if textutils and textutils.serialize then return textutils.serialize(tbl) end
  return nil
end

local function decode(line)
  if textutils and textutils.unserializeJSON then
    local ok, value = pcall(textutils.unserializeJSON, line)
    if ok and type(value) == "table" then return value end
  end
  if textutils and textutils.unserialiseJSON then
    local ok, value = pcall(textutils.unserialiseJSON, line)
    if ok and type(value) == "table" then return value end
  end
  if textutils and textutils.unserialize then
    local ok, value = pcall(textutils.unserialize, line)
    if ok and type(value) == "table" then return value end
  end
  return nil
end

function M.append(sessionId, role, content)
  local line = encode({ at = now(), role = role, content = tostring(content or "") })
  if not line then return false, "textutils serializer unavailable" end
  fileTool.append(pathFor(sessionId), line .. "\n")
  return true
end

function M.recent(sessionId, maxEntries)
  maxEntries = tonumber(maxEntries) or 12
  local path = pathFor(sessionId)
  if not fs.exists(path) then return {} end
  local f = fs.open(path, "r")
  if not f then return {} end
  local entries = {}
  while true do
    local line = f.readLine()
    if not line then break end
    local item = decode(line)
    if item and (item.role == "user" or item.role == "assistant" or item.role == "system") then
      entries[#entries + 1] = { role = item.role, content = tostring(item.content or "") }
    end
  end
  f.close()
  local out = {}
  local start = math.max(1, #entries - maxEntries + 1)
  for i = start, #entries do out[#out + 1] = entries[i] end
  return out
end

function M.path(sessionId)
  return pathFor(sessionId)
end

return M
