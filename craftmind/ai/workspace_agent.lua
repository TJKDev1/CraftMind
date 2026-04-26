local providers = require("craftmind.providers")
local docs = require("craftmind.docs.index")
local tools = require("craftmind.ai.workspace_tools")

local M = {}

M.systemPrompt = [[You are CraftMind Agent, an autonomous ComputerCraft workspace agent.
You are running inside ComputerCraft Lua. Your workspace is the current working directory.
Act like OpenClaw: inspect files, create files, run commands, run Lua, then continue from observations.

Tools: emit exact XML blocks. No markdown fences around tool blocks.
- List workspace path:
<craftmind-list path="." />
- Read workspace file:
<craftmind-read path="relative/file.lua" />
- Write or append workspace file:
<craftmind-file path="relative/file.lua" mode="write">
-- contents
</craftmind-file>
- Run shell command from workspace:
<craftmind-exec command="ls" />
- Run raw Lua from workspace:
<craftmind-lua>
print("hi")
</craftmind-lua>

File/read/list paths are relative to workspace and cannot escape it. Shell/Lua run with full ComputerCraft permissions, so be careful with absolute paths. Prefer small, inspectable steps. Avoid interactive commands because they can hang. When done, reply with concise summary and no tool blocks.]]

function M.buildMessages(task, prior)
  local messages = {
    { role = "system", content = M.systemPrompt },
    { role = "system", content = "Workspace root: " .. tools.root() },
  }
  local ctx = docs.context(task)
  if ctx ~= "" then table.insert(messages, { role = "system", content = ctx }) end
  table.insert(messages, { role = "user", content = task })
  for _, msg in ipairs(prior or {}) do table.insert(messages, msg) end
  return messages
end

function M.ask(task, prior, opts)
  local messages = M.buildMessages(task, prior)
  return providers.chat(messages, opts or {})
end

return M
