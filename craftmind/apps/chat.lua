package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local chat = require("craftmind.ai.chat")
local config = require("craftmind.config")

settingsx.defineAll()

local history = {}

print("CraftMind Chat v" .. config.version)
print("Provider: " .. settingsx.provider() .. " | Model: " .. tostring(settingsx.model()))
print("Type /quit to exit. /settings to show config.")

while true do
  write("\nYou> ")
  local input = read()
  if input == "/quit" then break end
  if input == "/settings" then
    print("provider=" .. tostring(settingsx.provider()))
    print("model=" .. tostring(settingsx.model()))
    print("safety=" .. tostring(settingsx.safety()))
    print("profile=" .. tostring(settingsx.profile()))
  else
    local reply, err = chat.ask(history, input)
    if not reply then
      print("Error: " .. tostring(err))
    else
      print("\nCraftMind> " .. reply)
      table.insert(history, { role = "user", content = input })
      table.insert(history, { role = "assistant", content = reply })
      while #history > 12 do table.remove(history, 1) end
    end
  end
end
