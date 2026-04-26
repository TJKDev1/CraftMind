local loaded = {}

_G.require = function(name)
  if loaded[name] ~= nil then return loaded[name] end
  local base = "/" .. name:gsub("%.", "/")
  local candidates = { base .. ".lua", base .. "/init.lua" }
  for _, path in ipairs(candidates) do
    if fs.exists(path) and not fs.isDir(path) then
      loaded[name] = true
      local result = dofile(path)
      if result ~= nil then loaded[name] = result end
      return loaded[name]
    end
  end
  error("module not found: " .. name, 2)
end

local ok, err = pcall(dofile, "/tests/computercraft-smoke.lua")
if not ok then
  print("CraftMind ComputerCraft smoke FAILED")
  print(tostring(err))
  os.shutdown(1)
end

os.shutdown(0)
