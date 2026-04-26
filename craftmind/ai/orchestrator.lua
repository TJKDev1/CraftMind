local providers = require("craftmind.providers")
local context = require("craftmind.ai.context")
local identity = require("craftmind.identity")

local M = {}

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function M.agentReply(toId, fromId, message, history, opts)
  toId = identity.sanitizeId(toId or identity.defaultAgentId())
  fromId = identity.sanitizeId(fromId or "user")
  identity.ensureAgent(toId)

  local userText = "Message from agent `" .. fromId .. "`:\n\n" .. tostring(message or "")
  local basePrompt = [[You are a CraftMind agent replying inside a ComputerCraft multi-agent workspace.
Stay ComputerCraft-native: Lua, turtles, rednet, terminal UI, files, and safe workspace automation.
Reply as yourself using your identity/soul. Keep answers useful for another agent. If tool work is needed, describe the next step instead of pretending it was done.]]
  local messages = context.systemMessages(message or "", toId, basePrompt)
  for _, msg in ipairs(history or {}) do table.insert(messages, msg) end
  table.insert(messages, { role = "user", content = userText })

  local providerOpts = {}
  for k, v in pairs(opts or {}) do
    if k ~= "agentId" and k ~= "fromId" then providerOpts[k] = v end
  end
  return providers.chat(messages, providerOpts)
end

function M.sendMessage(fromId, toId, message, opts)
  fromId = identity.sanitizeId(fromId or identity.defaultAgentId())
  toId = identity.sanitizeId(toId or identity.defaultAgentId())
  message = trim(message or "")
  if message == "" then return false, "empty message" end
  identity.ensureAgent(fromId)
  identity.ensureAgent(toId)
  identity.appendInbox(toId, fromId, message)

  if opts and opts.noReply then return true, "message delivered to " .. toId end

  local reply, err = M.agentReply(toId, fromId, message, nil, opts)
  if not reply then return false, err end
  identity.appendInbox(fromId, toId, reply)
  return true, "reply from " .. toId .. ":\n" .. reply
end

return M
