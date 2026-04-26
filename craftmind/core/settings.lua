local config = require("craftmind.config")

local M = {}

local defs = {
  [config.settings.provider] = { description = "CraftMind AI provider", default = config.defaults.provider, type = "string" },
  [config.settings.model] = { description = "CraftMind model", default = config.providers[config.defaults.provider].defaultModel, type = "string" },
  [config.settings.safety] = { description = "CraftMind safety mode", default = config.defaults.safety, type = "string" },
  [config.settings.profile] = { description = "CraftMind permission profile", default = config.defaults.profile, type = "string" },
  [config.settings.rawLuaConfirm] = { description = "Raw Lua confirmation mode", default = config.defaults.rawLuaConfirm, type = "string" },
  [config.settings.docsMode] = { description = "Docs context mode", default = config.defaults.docsMode, type = "string" },
  [config.settings.groqKey] = { description = "Groq API key", default = "", type = "string" },
  [config.settings.geminiKey] = { description = "Gemini API key", default = "", type = "string" },
  [config.settings.nvidiaKey] = { description = "NVIDIA API key", default = "", type = "string" },
  [config.settings.openaiCompatKey] = { description = "OpenAI compatible API key", default = "", type = "string" },
  [config.settings.openaiCompatBaseUrl] = { description = "OpenAI compatible base URL", default = "", type = "string" },
}

function M.defineAll()
  for key, def in pairs(defs) do settings.define(key, def) end
  settings.save()
end

function M.get(key) return settings.get(key) end
function M.set(key, value) settings.set(key, value); settings.save() end

function M.provider() return settings.get(config.settings.provider) or config.defaults.provider end
function M.model() return settings.get(config.settings.model) or config.providers[M.provider()].defaultModel end
function M.safety() return settings.get(config.settings.safety) or config.defaults.safety end
function M.profile() return settings.get(config.settings.profile) or config.defaults.profile end
function M.rawLuaConfirm() return settings.get(config.settings.rawLuaConfirm) or config.defaults.rawLuaConfirm end
function M.docsMode() return settings.get(config.settings.docsMode) or config.defaults.docsMode end

return M
