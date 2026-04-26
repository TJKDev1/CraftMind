local config = require("craftmind.config")
local settingsx = require("craftmind.core.settings")
local httpx = require("craftmind.core.http")

local M = {}

local function toParts(messages)
  local contents = {}
  for _, m in ipairs(messages or {}) do
    local role = m.role == "assistant" and "model" or "user"
    table.insert(contents, { role = role, parts = { { text = m.content or "" } } })
  end
  return contents
end

function M.chat(opts)
  opts = opts or {}
  local apiKey = settingsx.get(config.settings.geminiKey)
  if not apiKey or apiKey == "" then return nil, "missing Gemini API key" end
  local model = opts.model or settingsx.model() or config.providers.gemini.defaultModel
  local url = "https://generativelanguage.googleapis.com/v1beta/" .. model .. ":generateContent?key=" .. apiKey
  local data, err = httpx.jsonPost(url, {
    contents = toParts(opts.messages or {}),
    generationConfig = { temperature = opts.temperature or 0.2 },
  })
  if not data then return nil, err end
  local cand = data.candidates and data.candidates[1]
  local parts = cand and cand.content and cand.content.parts
  if not parts or not parts[1] then return nil, "Gemini returned no content" end
  return parts[1].text or "", nil
end

return M
