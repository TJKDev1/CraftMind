local settingsx = require("craftmind.core.settings")
local logger = require("craftmind.core.logger")

local M = {}

local function confirm(prompt)
  write(prompt .. " [y/N] ")
  local ans = read()
  return ans == "y" or ans == "Y" or ans == "yes" or ans == "YES"
end

function M.preview(code)
  print("----- CraftMind Lua Preview -----")
  print(code)
  print("----------- End Preview ----------")
end

function M.canRunRawLua()
  local safety = settingsx.safety()
  local profile = settingsx.profile()
  if safety == "power" then return true end
  if profile == "admin" then return true end
  return false
end

function M.run(code, opts)
  opts = opts or {}
  if not code or code == "" then return false, "empty code" end

  if not M.canRunRawLua() then
    return false, "raw Lua blocked by safety/profile settings"
  end

  M.preview(code)
  local confirmMode = settingsx.rawLuaConfirm()
  if confirmMode == "always" or opts.confirm == true then
    if not confirm("Run this Lua code?") then return false, "cancelled" end
  end

  logger.info("Running raw Lua:\n" .. code)
  local fn, err = load(code, "craftmind_generated", "t", _ENV)
  if not fn then logger.error(err); return false, err end
  local ok, result = pcall(fn)
  if not ok then logger.error(result); return false, result end
  logger.info("Raw Lua complete")
  return true, result
end

return M
