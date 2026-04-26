local httpx = require("craftmind.core.http")

local M = {}

local function normalizeMessages(messages)
  local out = {}
  for _, m in ipairs(messages) do
    table.insert(out, { role = m.role or "user", content = m.content or "" })
  end
  return out
end

function M.chat(opts)
  local baseUrl = opts.baseUrl
  local apiKey = opts.apiKey
  local model = opts.model
  if not baseUrl or baseUrl == "" then return nil, "missing baseUrl" end
  if not apiKey or apiKey == "" then return nil, "missing apiKey" end
  if not model or model == "" then return nil, "missing model" end

  local payload = {
    model = model,
    messages = normalizeMessages(opts.messages or {}),
    temperature = opts.temperature or 0.2,
  }

  local data, err = httpx.jsonPost(baseUrl .. "/chat/completions", payload, {
    ["Authorization"] = "Bearer " .. apiKey,
  })
  if not data then return nil, err end
  local choice = data.choices and data.choices[1]
  if not choice then return nil, "provider returned no choices" end
  local msg = choice.message or {}
  return msg.content or choice.text or "", nil
end

return M
