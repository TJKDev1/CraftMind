local providers = require("craftmind.providers")
local docs = require("craftmind.docs.index")
local config = require("craftmind.config")

local M = {}

M.systemPrompt = [[You are CraftMind, a ComputerCraft AI assistant.
You can explain Lua, ComputerCraft APIs, turtle automation, rednet networking, and file changes.
When asked to write code, produce complete runnable Lua unless user asks for diff only.
When user asks you to create or edit a file, include a tool block exactly like:
<craftmind-file path="/path/to/file.lua" mode="write">
-- file contents here
</craftmind-file>
Use mode="append" only when user asks to append. Use mode="write" for complete file replacement.
Do not put markdown fences inside craftmind-file blocks unless they belong in the file.
When raw Lua execution is available, still explain risk and prefer small auditable code.]]

function M.buildMessages(history, userText)
  local ctx = docs.context(userText)
  local messages = {
    { role = "system", content = M.systemPrompt },
  }
  if ctx ~= "" then table.insert(messages, { role = "system", content = ctx }) end
  for _, msg in ipairs(history or {}) do table.insert(messages, msg) end
  table.insert(messages, { role = "user", content = userText })
  return messages
end

function M.ask(history, userText, opts)
  local messages = M.buildMessages(history, userText)
  return providers.chat(messages, opts or {})
end

return M
