local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
local fileTool = require("craftmind.tools.file")
local luaAgent = require("craftmind.ai.lua_agent")
local orchestrator = require("craftmind.ai.orchestrator")
local identity = require("craftmind.identity")

local M = {}

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function parseAttrs(attrText)
  local attrs = {}
  for k, v in string.gmatch(attrText or "", "([%w_%-]+)%s*=%s*\"([^\"]*)\"") do attrs[k] = v end
  for k, v in string.gmatch(attrText or "", "([%w_%-]+)%s*=%s*'([^']*)'") do attrs[k] = v end
  return attrs
end

local function truncate(text, maxLen)
  text = tostring(text or "")
  maxLen = maxLen or 4000
  if #text <= maxLen then return text end
  return text:sub(1, maxLen) .. "\n...[truncated " .. tostring(#text - maxLen) .. " chars]"
end

local function root()
  local r = settingsx.workspace and settingsx.workspace() or config.defaults.workspace
  r = trim(r or "/craftmind/workspace"):gsub("\\", "/")
  if r == "" or r:find("..", 1, true) then r = "/craftmind/workspace" end
  return r
end

local function ensureWorkspace()
  local r = root()
  if not fs.exists(r) then fs.makeDir(r) end
  return r
end

local function workspacePath(path)
  local r = ensureWorkspace()
  path = trim(path or ".")
  if path == "" or path == "." then return r end
  path = path:gsub("\\", "/")
  if path:find("..", 1, true) then return nil, "parent paths not allowed" end
  while path:sub(1, 1) == "/" do path = path:sub(2) end
  return fs.combine(r, path)
end

local function makeCapture()
  local native = term.current()
  local w, h = native.getSize()
  local lines = { "" }
  local x, y = 1, 1

  local function ensureLine(n)
    while #lines < n do table.insert(lines, "") end
  end

  local function writeText(text)
    text = tostring(text or "")
    for i = 1, #text do
      local ch = text:sub(i, i)
      if ch == "\n" then
        y = y + 1
        x = 1
        ensureLine(y)
      else
        ensureLine(y)
        local line = lines[y]
        if x > #line then line = line .. string.rep(" ", x - #line - 1) end
        lines[y] = line:sub(1, x - 1) .. ch .. line:sub(x + 1)
        x = x + 1
      end
    end
  end

  local target = {
    write = writeText,
    blit = function(text) writeText(text) end,
    clear = function() lines = { "" }; x = 1; y = 1 end,
    clearLine = function() ensureLine(y); lines[y] = ""; x = 1 end,
    getCursorPos = function() return x, y end,
    setCursorPos = function(nx, ny) x = math.max(1, tonumber(nx) or 1); y = math.max(1, tonumber(ny) or 1); ensureLine(y) end,
    setCursorBlink = function() end,
    getSize = function() return w, h end,
    scroll = function(n)
      n = tonumber(n) or 1
      for _ = 1, n do table.remove(lines, 1); table.insert(lines, "") end
    end,
    isColor = function() return native.isColor and native.isColor() or false end,
    isColour = function() return native.isColour and native.isColour() or false end,
    setTextColor = function() end,
    setTextColour = function() end,
    getTextColor = function() return colors and colors.white or 1 end,
    getTextColour = function() return colors and colors.white or 1 end,
    setBackgroundColor = function() end,
    setBackgroundColour = function() end,
    getBackgroundColor = function() return colors and colors.black or 32768 end,
    getBackgroundColour = function() return colors and colors.black or 32768 end,
    getPaletteColor = native.getPaletteColor and function(...) return native.getPaletteColor(...) end or nil,
    getPaletteColour = native.getPaletteColour and function(...) return native.getPaletteColour(...) end or nil,
    setPaletteColor = function() end,
    setPaletteColour = function() end,
  }

  local oldPrint = _G.print
  local oldWrite = _G.write
  local oldTerm = term.current()

  local function start()
    term.redirect(target)
    _G.write = function(text) writeText(text) end
    _G.print = function(...)
      local parts = {}
      for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
      writeText(table.concat(parts, "\t") .. "\n")
    end
  end

  local function stop()
    _G.print = oldPrint
    _G.write = oldWrite
    term.redirect(oldTerm)
  end

  local function text()
    return table.concat(lines, "\n"):gsub("%s+$", "")
  end

  return start, stop, text
end

local function withCapture(fn)
  local start, stop, text = makeCapture()
  start()
  local ok, a, b = pcall(fn)
  stop()
  if not ok then return false, tostring(a), text() end
  return true, a, text(), b
end

function M.canRun()
  return luaAgent.canRunRawLua()
end

function M.runShell(command)
  if not M.canRun() then return false, "shell execution blocked by safety/profile settings" end
  command = trim(command)
  if command == "" then return false, "empty command" end
  local r = ensureWorkspace()
  local oldDir = shell.dir()
  local ok, result, output = withCapture(function()
    shell.setDir(r)
    return shell.run(command)
  end)
  shell.setDir(oldDir)
  if not ok then return false, result .. (output ~= "" and ("\n" .. output) or "") end
  if result == false then return false, output ~= "" and output or "command returned false" end
  return true, output
end

function M.runLua(code)
  if not M.canRun() then return false, "raw Lua execution blocked by safety/profile settings" end
  code = code or ""
  if trim(code) == "" then return false, "empty Lua" end
  local r = ensureWorkspace()
  local oldDir = shell.dir()
  local ok, result, output, extra = withCapture(function()
    shell.setDir(r)
    local fn, err = load(code, "craftmind_workspace", "t", _ENV)
    if not fn then error(err, 0) end
    return fn()
  end)
  shell.setDir(oldDir)
  if not ok then return false, result .. (output ~= "" and ("\n" .. output) or "") end
  if result ~= nil then output = output .. (output ~= "" and "\n" or "") .. "return: " .. tostring(result) end
  if extra ~= nil then output = output .. (output ~= "" and "\n" or "") .. "extra: " .. tostring(extra) end
  return true, output
end

function M.extract(text)
  local ops = {}
  text = text or ""

  for attrText, body in string.gmatch(text, "<craftmind%-file(.-)>(.-)</craftmind%-file>") do
    local attrs = parseAttrs(attrText)
    table.insert(ops, { type = "file", path = attrs.path, mode = attrs.mode or "write", content = body:gsub("^\n", ""):gsub("\n$", "") })
  end
  for attrText in string.gmatch(text, "<craftmind%-read(.-)/>") do
    local attrs = parseAttrs(attrText)
    table.insert(ops, { type = "read", path = attrs.path })
  end
  for attrText in string.gmatch(text, "<craftmind%-list(.-)/>") do
    local attrs = parseAttrs(attrText)
    table.insert(ops, { type = "list", path = attrs.path or "." })
  end
  for attrText in string.gmatch(text, "<craftmind%-exec(.-)/>") do
    local attrs = parseAttrs(attrText)
    table.insert(ops, { type = "exec", command = attrs.command })
  end
  for attrText, body in string.gmatch(text, "<craftmind%-exec(.-)>(.-)</craftmind%-exec>") do
    local attrs = parseAttrs(attrText)
    table.insert(ops, { type = "exec", command = attrs.command or body })
  end
  for body in string.gmatch(text, "<craftmind%-lua>(.-)</craftmind%-lua>") do
    table.insert(ops, { type = "lua", code = body:gsub("^\n", ""):gsub("\n$", "") })
  end
  for attrText, body in string.gmatch(text, "<craftmind%-message(.-)>(.-)</craftmind%-message>") do
    local attrs = parseAttrs(attrText)
    table.insert(ops, { type = "message", to = attrs.to or attrs.agent or attrs.id, from = attrs.from, content = body:gsub("^\n", ""):gsub("\n$", "") })
  end
  return ops
end

function M.stripToolBlocks(text)
  text = text or ""
  text = text:gsub("<craftmind%-file.->.-</craftmind%-file>", "")
  text = text:gsub("<craftmind%-lua>.-</craftmind%-lua>", "")
  text = text:gsub("<craftmind%-exec.->.-</craftmind%-exec>", "")
  text = text:gsub("<craftmind%-message.->.-</craftmind%-message>", "")
  text = text:gsub("<craftmind%-read.*/>", "")
  text = text:gsub("<craftmind%-list.*/>", "")
  text = text:gsub("<craftmind%-exec.*/>", "")
  return trim(text)
end

function M.run(op)
  if op.type == "file" then
    local path, err = workspacePath(op.path)
    if not path then return false, err end
    if op.mode ~= "write" and op.mode ~= "append" then return false, "unsupported file mode: " .. tostring(op.mode) end
    if op.mode == "append" then fileTool.append(path, op.content or "") else fileTool.write(path, op.content or "") end
    return true, op.mode .. " " .. path
  elseif op.type == "read" then
    local path, err = workspacePath(op.path)
    if not path then return false, err end
    local content, readErr = fileTool.read(path)
    if not content then return false, readErr end
    return true, truncate(content)
  elseif op.type == "list" then
    local path, err = workspacePath(op.path)
    if not path then return false, err end
    if not fs.exists(path) then return false, "not found: " .. path end
    if not fs.isDir(path) then return false, "not directory: " .. path end
    return true, table.concat(fs.list(path), "\n")
  elseif op.type == "exec" then
    return M.runShell(op.command)
  elseif op.type == "lua" then
    return M.runLua(op.code)
  elseif op.type == "message" then
    local from = op.from or (identity.defaultAgentId and identity.defaultAgentId()) or "main"
    return orchestrator.sendMessage(from, op.to, op.content)
  end
  return false, "unknown op: " .. tostring(op.type)
end

function M.runAll(ops)
  local lines = {}
  for i, op in ipairs(ops or {}) do
    local ok, res = M.run(op)
    lines[#lines + 1] = "[" .. i .. "] " .. tostring(op.type) .. " " .. (ok and "OK" or "ERR")
    lines[#lines + 1] = truncate(res or "")
  end
  return table.concat(lines, "\n")
end

function M.root()
  return root()
end

function M.ensureWorkspace()
  return ensureWorkspace()
end

return M
