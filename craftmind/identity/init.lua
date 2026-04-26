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

local function safeRoot()
  local r = settingsx.workspace and settingsx.workspace() or config.defaults.workspace
  r = trim(r or config.defaults.workspace):gsub("\\", "/")
  if r == "" or r:find("..", 1, true) then r = config.defaults.workspace end
  return r
end

local function ensureDir(path)
  if not fs.exists(path) then fs.makeDir(path) end
end

local function ensureParent(path)
  local dir = fs.getDir(path)
  if dir ~= "" then ensureDir(dir) end
end

local function writeIfMissing(path, content)
  ensureParent(path)
  if not fs.exists(path) then fileTool.write(path, content) end
end

local function readIfExists(path)
  if not fs.exists(path) then return "" end
  local ok, text = pcall(fileTool.read, path)
  if not ok or not text then return "" end
  return text
end

local function replaceAllIfExists(path, old, new)
  local text = readIfExists(path)
  if text == "" or old == "" then return end
  local changed = false
  local start = 1
  while true do
    local s, e = text:find(old, start, true)
    if not s then break end
    text = text:sub(1, s - 1) .. new .. text:sub(e + 1)
    start = s + #new
    changed = true
  end
  if changed then fileTool.write(path, text) end
end

local function truncate(text, maxLen)
  text = tostring(text or "")
  maxLen = maxLen or 5000
  if #text <= maxLen then return text end
  return text:sub(1, maxLen) .. "\n...[truncated " .. tostring(#text - maxLen) .. " chars]"
end

function M.sanitizeId(id)
  id = trim(id or "main"):lower():gsub("%s+", "-"):gsub("[^%w_%-]", "")
  if id == "" then id = "main" end
  return id
end

function M.workspaceRoot()
  local r = safeRoot()
  ensureDir(r)
  return r
end

function M.docsDir()
  local dir = fs.combine(M.workspaceRoot(), ".craftmind/docs")
  ensureDir(dir)
  return dir
end

local function writeGenerated(path, content)
  ensureParent(path)
  fileTool.write(path, content or "")
end

local function mirrorBundledDocs(dir)
  local srcDir = "/craftmind/docs"
  if not fs.exists(srcDir) or not fs.isDir(srcDir) then return end
  local dstDir = fs.combine(dir, "bundled")
  ensureDir(dstDir)
  for _, name in ipairs(fs.list(srcDir)) do
    if name:sub(-3) == ".md" then
      local src = fs.combine(srcDir, name)
      if not fs.isDir(src) then
        local text = readIfExists(src)
        if text ~= "" then
          writeGenerated(fs.combine(dstDir, name), [[<!-- Generated mirror of /craftmind/docs/]] .. name .. [[. Edit workspace docs outside bundled/ for durable local changes. -->

]] .. text)
        end
      end
    end
  end
end

function M.ensureDocs()
  local dir = M.docsDir()
  writeIfMissing(fs.combine(dir, "craftmind.md"), [[# Workspace CraftMind docs

These docs live inside the CraftMind workspace so agents can inspect and improve them safely.

CraftMind is an OpenClaw-style ComputerCraft agent system. It should stay focused on Lua, turtles, rednet, terminal UI, peripherals, and safe workspace automation.

Default safety model:
- Workspace file/list/read/message tools are allowed inside the workspace.
- Shell and raw Lua require `safety=power`.
- Remote turtle commands require matching `craftmind.auth_token`; blank token locks remote control except discovery.
- OpenClaw-style bootstrap files live at workspace root: `AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`, and `MEMORY.md`.
- Identity files live under `.craftmind/agents/<id>/`.
- Session logs live under `.craftmind/sessions/` as JSONL.
- Bundled package docs are mirrored to `.craftmind/docs/bundled/` so workspace-scoped tools can read them on demand.
]])
  writeIfMissing(fs.combine(dir, "self-modification.md"), [[# Self modification

CraftMind agents may improve workspace-scoped identity and documentation files when the user asks or when a durable correction is clearly useful.

Good self-modification targets:
- `AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`, `MEMORY.md`
- `.craftmind/agents/<id>/soul.md`
- `.craftmind/agents/<id>/memory.md`
- `.craftmind/agents/<id>/tools.md`
- `.craftmind/docs/*.md`

Do not bypass workspace restrictions. Do not weaken shell/raw Lua safety gates. Prefer local docs outside `.craftmind/docs/bundled/`; bundled docs are regenerated from `/craftmind/docs`.
]])
  writeIfMissing(fs.combine(dir, "computercraft-quick-reference.md"), [[# ComputerCraft quick reference

ComputerCraft runs Lua programs on computers, turtles, pocket computers, and command computers. Common APIs include `shell`, `fs`, `term`, `rednet`, `peripheral`, `settings`, `textutils`, and `http`.

## Turtles

Useful turtle calls: `turtle.forward`, `back`, `up`, `down`, `turnLeft`, `turnRight`, `dig`, `digUp`, `digDown`, `place`, `placeUp`, `placeDown`, `select`, `getItemCount`, `refuel`, `getFuelLevel`, `inspect`, `compare`, `suck`, and `drop`.

Ask before turtle movement or digging that could risk blocks, items, fuel, or position.

## Rednet

Rednet needs a modem opened with `rednet.open(side)`. Send with `rednet.send(id, message, protocol)`, receive with `rednet.receive(protocol, timeout)`, and broadcast with `rednet.broadcast(message, protocol)`. CraftMind remote turtle commands require matching `craftmind.auth_token`; a blank token locks remote control except discovery.

## HTTP

HTTP must be enabled in server config. Use `http.get`, `http.post`, `response.readAll()`, and `response.close()`. Encode/decode JSON with `textutils.serializeJSON` and `textutils.unserializeJSON`.

## Filesystem

Use `fs.exists`, `fs.open`, `fs.makeDir`, `fs.delete`, `fs.list`, and `fs.getDir`. File handle methods include `readAll`, `write`, `writeLine`, and `close`.
]])
  mirrorBundledDocs(dir)
  replaceAllIfExists(fs.combine(dir, "craftmind.md"), "`safety=power` or `profile=admin`", "`safety=power`")
  replaceAllIfExists(fs.combine(dir, "craftmind.md"), "power/admin", "power mode")
  if not readIfExists(fs.combine(dir, "craftmind.md")):find("blank token locks remote control", 1, true) then
    replaceAllIfExists(fs.combine(dir, "craftmind.md"), "- Shell and raw Lua require `safety=power`.", "- Shell and raw Lua require `safety=power`.\n- Remote turtle commands require matching `craftmind.auth_token`; blank token locks remote control except discovery.")
  end
  if not readIfExists(fs.combine(dir, "craftmind.md")):find("bundled/", 1, true) then
    replaceAllIfExists(fs.combine(dir, "craftmind.md"), "- Session logs live under `.craftmind/sessions/` as JSONL.", "- Session logs live under `.craftmind/sessions/` as JSONL.\n- Bundled package docs are mirrored to `.craftmind/docs/bundled/` so workspace-scoped tools can read them on demand.")
  end
  return dir
end

function M.agentsDir()
  local dir = fs.combine(M.workspaceRoot(), ".craftmind/agents")
  ensureDir(dir)
  return dir
end

function M.agentDir(id)
  return fs.combine(M.agentsDir(), M.sanitizeId(id))
end

function M.defaultAgentId()
  local id = settingsx.defaultAgent and settingsx.defaultAgent() or config.defaults.defaultAgent
  return M.sanitizeId(id or "main")
end

function M.setDefaultAgent(id)
  id = M.sanitizeId(id)
  settingsx.set(config.settings.defaultAgent, id)
  return id
end

function M.ensureAgent(id, opts)
  opts = opts or {}
  id = M.sanitizeId(id or M.defaultAgentId())
  local dir = M.agentDir(id)
  ensureDir(dir)
  M.ensureDocs()

  local name = trim(opts.name or id)
  if name == "" then name = id end
  local soul = trim(opts.soul or "")
  if soul == "" then
    soul = "I am a CraftMind ComputerCraft agent. I help with Lua programs, turtles, rednet, terminal UI, and safe workspace automation. I stay inspectable, ask before risky actions, and keep my behavior ComputerCraft-native."
  end

  writeIfMissing(fs.combine(dir, "identity.md"), "# Identity\n\nName: " .. name .. "\nAgent ID: " .. id .. "\nHome: .craftmind/agents/" .. id .. "\nCreated: " .. now() .. "\n\nI am a CraftMind agent living inside a ComputerCraft workspace.\n")
  writeIfMissing(fs.combine(dir, "soul.md"), "# Soul\n\n" .. soul .. "\n")
  writeIfMissing(fs.combine(dir, "tools.md"), [[# Tools

I can ask CraftMind to use inspectable XML tool blocks:

- `<craftmind-list path="." />` lists workspace paths.
- `<craftmind-read path="file.lua" />` reads workspace files.
- `<craftmind-file path="file.lua" mode="write">...</craftmind-file>` writes workspace files.
- `<craftmind-file path="file.lua" mode="append">...</craftmind-file>` appends workspace files.
- `<craftmind-replace path="file.lua"><old>exact old text</old><new>exact new text</new></craftmind-replace>` replaces one exact match in a workspace file.
- `<craftmind-exec command="ls" />` runs shell commands only in power mode.
- `<craftmind-lua>...</craftmind-lua>` runs Lua only in power mode.
- `<craftmind-message to="agent-id">message</craftmind-message>` sends a message to another CraftMind agent.

File/list/read paths are workspace-scoped. Shell and Lua are more powerful and must stay small, auditable, and ComputerCraft-focused.
]])
  writeIfMissing(fs.combine(dir, "memory.md"), "# Memory\n\n- Hatched as `" .. id .. "` on " .. now() .. ".\n")
  writeIfMissing(fs.combine(dir, "inbox.md"), "# Inbox\n\n")
  writeIfMissing(fs.combine(dir, "orchestration.md"), [[# Orchestration

This agent can work alone by default. In a multi-agent workspace, messages are delivered to inbox files and may be answered by the receiving agent.

Conventions:
- Keep messages short and task-focused.
- State which files or ComputerCraft systems you touched.
- Do not delegate unsafe shell/Lua work unless the user enabled power mode.
]])

  replaceAllIfExists(fs.combine(dir, "tools.md"), "power/admin mode", "power mode")
  replaceAllIfExists(fs.combine(dir, "tools.md"), "`safety=power` or `profile=admin`", "`safety=power`")
  replaceAllIfExists(fs.combine(dir, "orchestration.md"), "power/admin mode", "power mode")

  return id, dir
end

function M.listAgents()
  local dir = M.agentsDir()
  local out = {}
  if not fs.exists(dir) then return out end
  for _, id in ipairs(fs.list(dir)) do
    local path = fs.combine(dir, id)
    if fs.isDir(path) then table.insert(out, id) end
  end
  table.sort(out)
  return out
end

function M.path(id, fileName)
  id = M.sanitizeId(id or M.defaultAgentId())
  return fs.combine(M.agentDir(id), fileName)
end

function M.appendInbox(id, from, message)
  id = M.sanitizeId(id)
  M.ensureAgent(id)
  local entry = "\n## " .. now() .. " from " .. tostring(from or "user") .. "\n\n" .. tostring(message or "") .. "\n"
  fileTool.append(M.path(id, "inbox.md"), entry)
  return true
end

function M.appendMemory(id, text)
  id = M.sanitizeId(id)
  M.ensureAgent(id)
  fileTool.append(M.path(id, "memory.md"), "\n- " .. tostring(text or "") .. "\n")
  return true
end

function M.context(id)
  id = M.sanitizeId(id or M.defaultAgentId())
  M.ensureAgent(id)
  local dirRel = ".craftmind/agents/" .. id
  local files = { "identity.md", "soul.md", "tools.md", "memory.md", "orchestration.md", "inbox.md" }
  local lines = {
    "CraftMind agent identity context:",
    "Active agent id: " .. id,
    "Workspace root also contains OpenClaw-style bootstrap files: AGENTS.md, SOUL.md, USER.md, TOOLS.md, HEARTBEAT.md, and MEMORY.md.",
    "Identity files live in workspace at " .. dirRel .. ". Workspace CraftMind docs live at .craftmind/docs. The agent may inspect or edit these files with workspace tools when the user asks it to refine itself or when a durable memory/personality/docs update is appropriate.",
  }
  for _, fileName in ipairs(files) do
    local text = readIfExists(fs.combine(M.agentDir(id), fileName))
    if text ~= "" then
      lines[#lines + 1] = "\n--- " .. dirRel .. "/" .. fileName .. " ---\n" .. truncate(text, fileName == "inbox.md" and 2500 or 4000)
    end
  end
  return table.concat(lines, "\n")
end

function M.rehatch(id, name, soul)
  id = M.sanitizeId(id)
  local _, dir = M.ensureAgent(id, { name = name, soul = soul })
  name = trim(name or id)
  if name == "" then name = id end
  soul = trim(soul or "")
  if soul == "" then
    soul = "I am a CraftMind ComputerCraft agent. I help with Lua programs, turtles, rednet, terminal UI, and safe workspace automation. I stay inspectable, ask before risky actions, and keep my behavior ComputerCraft-native."
  end
  fileTool.write(fs.combine(dir, "identity.md"), "# Identity\n\nName: " .. name .. "\nAgent ID: " .. id .. "\nHome: .craftmind/agents/" .. id .. "\nUpdated: " .. now() .. "\n\nI am a CraftMind agent living inside a ComputerCraft workspace.\n")
  fileTool.write(fs.combine(dir, "soul.md"), "# Soul\n\n" .. soul .. "\n")
  M.appendMemory(id, "Re-hatched/updated identity on " .. now() .. ".")
  M.setDefaultAgent(id)
  return id, dir
end

function M.hatch(id, name, soul)
  id = M.sanitizeId(id)
  local dir = M.agentDir(id)
  if fs.exists(dir) then return nil, "agent already exists: " .. id end
  M.ensureAgent(id, { name = name, soul = soul })
  M.setDefaultAgent(id)
  return id, dir
end

return M
