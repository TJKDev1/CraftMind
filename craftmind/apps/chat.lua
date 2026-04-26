package.path = "/?.lua;/?/init.lua;" .. package.path

local settingsx = require("craftmind.core.settings")
local chat = require("craftmind.ai.chat")
local config = require("craftmind.config")
local render = require("craftmind.ui.render")
local tools = require("craftmind.ai.tool_runner")
local identity = require("craftmind.identity")

settingsx.defineAll()

local history = {}
local activeAgent = identity.defaultAgentId()
identity.ensureAgent(activeAgent)

print("CraftMind Chat v" .. config.version)
print("Provider: " .. settingsx.provider() .. " | Model: " .. tostring(settingsx.model()))
print("Agent: " .. activeAgent .. " (identity: .craftmind/agents/" .. activeAgent .. ")")
print("Type /quit to exit. /settings to show config. /agent <id> switches.")

while true do
  write("\nYou> ")
  local input = read()
  if input == "/quit" then break end
  if input == "/settings" then
    print("provider=" .. tostring(settingsx.provider()))
    print("model=" .. tostring(settingsx.model()))
    print("safety=" .. tostring(settingsx.safety()))
    print("profile=" .. tostring(settingsx.profile()))
    print("workspace=" .. tostring(settingsx.workspace()))
    print("agent=" .. tostring(activeAgent))
  elseif input:sub(1, 7) == "/agent " then
    activeAgent = identity.sanitizeId(input:sub(8))
    identity.ensureAgent(activeAgent)
    identity.setDefaultAgent(activeAgent)
    history = {}
    print("Active agent: " .. activeAgent)
  elseif input == "/agents" then
    for _, id in ipairs(identity.listAgents()) do print((id == activeAgent and "* " or "  ") .. id) end
  else
    local reply, err = chat.ask(history, input, { agentId = activeAgent })
    if not reply then
      render.error(err)
    else
      local display = tools.stripToolBlocks(reply)
      render.renderAssistant(display)
      local results = tools.runAllFromText(reply)
      for _, r in ipairs(results) do
        if r.ok then print("File changed: " .. tostring(r.result)) else print("File change skipped: " .. tostring(r.result)) end
      end
      table.insert(history, { role = "user", content = input })
      table.insert(history, { role = "assistant", content = display })
      while #history > 12 do table.remove(history, 1) end
    end
  end
end
