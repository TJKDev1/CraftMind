local settingsx = require("craftmind.core.settings")

local M = {}

local curated = {
  {
    title = "CraftMind OpenClaw-style architecture",
    text = "CraftMind maps OpenClaw's channel/brain/body architecture to ComputerCraft. Channel means terminal today plus future rednet/turtle/http adapters. Brain means provider-agnostic prompt assembly from AGENTS.md, SOUL.md, USER.md, TOOLS.md, HEARTBEAT.md, MEMORY.md, identity files, docs, skills, and session logs. Body means workspace tools, agent messaging, shell/Lua gated by safety, and ComputerCraft actuators like turtles and rednet.",
  },
  {
    title = "CraftMind identity and hatching",
    text = "CraftMind agents hatch into workspace identity files under .craftmind/agents/<id> including identity.md, soul.md, tools.md, memory.md, inbox.md, and orchestration.md. Workspace root bootstrap files AGENTS.md, SOUL.md, USER.md, TOOLS.md, HEARTBEAT.md, and MEMORY.md are also injected as durable context. These files are ComputerCraft-focused and may be read or edited through workspace-scoped tools.",
  },
  {
    title = "CraftMind multi-agent orchestration",
    text = "CraftMind supports one default agent by default and optional multi-agent workspaces. Agents can send messages using craftmind-message blocks; inbox.md records messages. Keep delegation safe, auditable, and ComputerCraft-native.",
  },
  {
    title = "ComputerCraft basics",
    text = "ComputerCraft runs Lua programs on computers, turtles, pocket computers, and command computers. Common APIs: shell, fs, term, rednet, peripheral, settings, textutils, http.",
  },
  {
    title = "Turtle basics",
    text = "Turtles expose turtle.forward/back/up/down, turnLeft/turnRight, dig/digUp/digDown, place/placeUp/placeDown, select, getItemCount, refuel, getFuelLevel, inspect, compare, suck, drop.",
  },
  {
    title = "Rednet basics",
    text = "rednet uses modems. Open side with rednet.open(side). Send messages with rednet.send(id, message, protocol). Receive with rednet.receive(protocol, timeout). Broadcast with rednet.broadcast(message, protocol).",
  },
  {
    title = "HTTP basics",
    text = "HTTP must be enabled on server. Use http.get, http.post, response.readAll(), response.close(). JSON via textutils.serializeJSON and textutils.unserializeJSON.",
  },
  {
    title = "Filesystem basics",
    text = "Use fs.exists, fs.open, fs.makeDir, fs.delete, fs.list, fs.getDir. File handle methods include readAll, write, writeLine, close.",
  },
}

local function loadMarkdownDir(dir, label)
  local docs = {}
  if not fs or not fs.exists or not fs.exists(dir) then return docs end
  for _, name in ipairs(fs.list(dir)) do
    if name:sub(-3) == ".md" then
      local path = fs.combine(dir, name)
      if not fs.isDir(path) then
        local f = fs.open(path, "r")
        if f then
          local body = f.readAll()
          f.close()
          table.insert(docs, { title = label .. ": " .. name, text = body })
        end
      end
    end
  end
  return docs
end

local function loadMarkdownDocs()
  local docs = {}
  for _, doc in ipairs(loadMarkdownDir("/craftmind/docs", "CraftMind docs")) do table.insert(docs, doc) end
  local workspace = settingsx.workspace and settingsx.workspace() or "/craftmind/workspace"
  local workspaceDocs = fs and fs.combine and fs.combine(workspace, ".craftmind/docs") or nil
  if workspaceDocs then
    for _, doc in ipairs(loadMarkdownDir(workspaceDocs, "Workspace CraftMind docs")) do table.insert(docs, doc) end
  end
  return docs
end

local function allDocs()
  local out = {}
  for _, doc in ipairs(curated) do table.insert(out, doc) end
  for _, doc in ipairs(loadMarkdownDocs()) do table.insert(out, doc) end
  return out
end

local function score(q, text)
  q = string.lower(q or "")
  text = string.lower(text or "")
  local n = 0
  for word in string.gmatch(q, "%w+") do
    if #word > 2 and string.find(text, word, 1, true) then n = n + 1 end
  end
  return n
end

function M.search(query, limit)
  if settingsx.docsMode() == "off" then return {} end
  local hits = {}
  for _, doc in ipairs(allDocs()) do
    table.insert(hits, { score = score(query, doc.title .. " " .. doc.text), title = doc.title, text = doc.text })
  end
  table.sort(hits, function(a, b) return a.score > b.score end)
  local out = {}
  for i = 1, math.min(limit or 3, #hits) do
    if hits[i].score > 0 then table.insert(out, hits[i]) end
  end
  return out
end

function M.context(query)
  local hits = M.search(query, 4)
  if #hits == 0 then return "" end
  local lines = { "Relevant ComputerCraft docs:" }
  for _, h in ipairs(hits) do
    table.insert(lines, "- " .. h.title .. ": " .. h.text)
  end
  return table.concat(lines, "\n")
end

return M
