local fileTool = require("craftmind.tools.file")

local M = {}

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function confirm(prompt)
  write(prompt .. " [y/N] ")
  local ans = read()
  return ans == "y" or ans == "Y" or ans == "yes" or ans == "YES"
end

local function safePath(path)
  path = trim(path)
  if path == "" then return nil, "empty path" end
  if path:find("%.%.", 1, true) then return nil, "parent paths not allowed" end
  if path:sub(1, 1) ~= "/" then path = "/" .. path end
  return path
end

local function parseAttrs(attrText)
  local attrs = {}
  for k, v in string.gmatch(attrText or "", "([%w_%-]+)%s*=%s*\"([^\"]*)\"") do
    attrs[k] = v
  end
  for k, v in string.gmatch(attrText or "", "([%w_%-]+)%s*=%s*'([^']*)'") do
    attrs[k] = v
  end
  return attrs
end

function M.extract(text)
  local ops = {}
  for attrText, body in string.gmatch(text or "", "<craftmind%-file(.-)>(.-)</craftmind%-file>") do
    local attrs = parseAttrs(attrText)
    table.insert(ops, {
      type = "file",
      path = attrs.path,
      mode = attrs.mode or "write",
      content = body:gsub("^\n", ""):gsub("\n$", ""),
    })
  end
  return ops
end

function M.stripToolBlocks(text)
  return (text or ""):gsub("<craftmind%-file.->.-</craftmind%-file>", "")
end

function M.runFileOp(op)
  local path, err = safePath(op.path)
  if not path then return false, err end
  local mode = op.mode or "write"
  if mode ~= "write" and mode ~= "append" then return false, "unsupported file mode: " .. tostring(mode) end

  print("")
  print("CraftMind wants to " .. mode .. " file:")
  print(path)
  print("----- file preview -----")
  print(op.content or "")
  print("-------- end ----------")

  if not confirm("Apply file change?") then return false, "cancelled" end

  if mode == "append" then
    fileTool.append(path, op.content or "")
  else
    fileTool.write(path, op.content or "")
  end
  return true, path
end

function M.runAllFromText(text)
  local ops = M.extract(text)
  local results = {}
  for _, op in ipairs(ops) do
    if op.type == "file" then
      local ok, res = M.runFileOp(op)
      table.insert(results, { ok = ok, result = res })
    end
  end
  return results
end

return M
