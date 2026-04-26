local workspaceTools = require("craftmind.ai.workspace_tools")

local M = {}

local function confirm(prompt)
  write(prompt .. " [y/N] ")
  local ans = read()
  return ans == "y" or ans == "Y" or ans == "yes" or ans == "YES"
end

local function previewOp(op)
  print("")
  if op.type == "file" then
    print("CraftMind wants to " .. tostring(op.mode or "write") .. " workspace file:")
    print(tostring(op.path or ""))
    print("----- file preview -----")
    print(op.content or "")
    print("-------- end ----------")
    return "Apply file change?"
  elseif op.type == "replace" then
    print("CraftMind wants to replace text in workspace file:")
    print(tostring(op.path or ""))
    print("----- old text -----")
    print(op.old or "")
    print("----- new text -----")
    print(op.new or "")
    print("-------- end -------")
    return "Apply replacement?"
  end
  return nil
end

function M.extract(text)
  local out = {}
  for _, op in ipairs(workspaceTools.extract(text)) do
    if op.type == "file" or op.type == "replace" then table.insert(out, op) end
  end
  return out
end

function M.stripToolBlocks(text)
  return workspaceTools.stripToolBlocks(text)
end

function M.runFileOp(op)
  local prompt = previewOp(op)
  if not prompt then return false, "unsupported chat tool: " .. tostring(op.type) end
  if not confirm(prompt) then return false, "cancelled" end
  return workspaceTools.run(op)
end

function M.runAllFromText(text)
  local ops = M.extract(text)
  local results = {}
  for _, op in ipairs(ops) do
    local ok, res = M.runFileOp(op)
    table.insert(results, { ok = ok, result = res })
  end
  return results
end

return M
