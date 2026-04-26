local settingsx = require("craftmind.core.settings")

local M = {}

local curated = {
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
  for _, doc in ipairs(curated) do
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
