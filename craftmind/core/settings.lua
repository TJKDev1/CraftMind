local config = require("craftmind.config")

local M = {}

local defs = {
  [config.settings.provider] = { description = "CraftMind AI provider", default = config.defaults.provider, type = "string" },
  [config.settings.model] = { description = "CraftMind model", default = config.providers[config.defaults.provider].defaultModel, type = "string" },
  [config.settings.safety] = { description = "CraftMind safety mode", default = config.defaults.safety, type = "string" },
  [config.settings.profile] = { description = "Deprecated CraftMind legacy profile", default = config.defaults.profile, type = "string" },
  [config.settings.rawLuaConfirm] = { description = "Raw Lua confirmation mode", default = config.defaults.rawLuaConfirm, type = "string" },
  [config.settings.docsMode] = { description = "Docs context mode", default = config.defaults.docsMode, type = "string" },
  [config.settings.workspace] = { description = "CraftMind Agent workspace", default = config.defaults.workspace, type = "string" },
  [config.settings.agentMaxSteps] = { description = "CraftMind Agent max steps", default = config.defaults.agentMaxSteps, type = "number" },
  [config.settings.defaultAgent] = { description = "Default CraftMind agent id", default = config.defaults.defaultAgent, type = "string" },
  [config.settings.onboardingCompleted] = { description = "CraftMind onboarding completed", default = config.defaults.onboardingCompleted, type = "boolean" },
  [config.settings.rednetGatewayEnabled] = { description = "CraftMind rednet gateway enabled", default = config.defaults.rednetGatewayEnabled, type = "boolean" },
  [config.settings.serverName] = { description = "CraftMind turtle server name", default = config.defaults.serverName, type = "string" },
  [config.settings.authToken] = { description = "CraftMind rednet auth token", default = config.defaults.authToken, type = "string" },
  [config.settings.groqKey] = { description = "Groq API key", default = "", type = "string" },
  [config.settings.geminiKey] = { description = "Gemini API key", default = "", type = "string" },
  [config.settings.nvidiaKey] = { description = "NVIDIA API key", default = "", type = "string" },
  [config.settings.openaiCompatKey] = { description = "OpenAI compatible API key", default = "", type = "string" },
  [config.settings.openaiCompatBaseUrl] = { description = "OpenAI compatible base URL", default = "", type = "string" },
}

function M.defineAll()
  for key, def in pairs(defs) do settings.define(key, def) end

  -- Legacy migration: old CraftMind used profile=admin as a second way to
  -- unlock shell/raw Lua and profile=singleplayer to allow unauthenticated
  -- rednet control. Keep the user's explicit admin power, but collapse the
  -- runtime model to two clear gates: safety=power and auth_token.
  local legacyProfile = settings.get(config.settings.profile)
  if legacyProfile == "admin" and settings.get(config.settings.safety) ~= "power" then
    settings.set(config.settings.safety, "power")
  end
  if legacyProfile == "admin" or legacyProfile == "singleplayer" then
    settings.set(config.settings.profile, config.defaults.profile)
  end

  -- Legacy docs modes injected retrieved snippets by default. New default mirrors
  -- OpenClaw: inject a docs manifest and let agents read workspace docs on demand.
  local legacyDocsMode = settings.get(config.settings.docsMode)
  if legacyDocsMode == "curated" or legacyDocsMode == "full" then
    settings.set(config.settings.docsMode, config.defaults.docsMode)
  end

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
function M.workspace() return settings.get(config.settings.workspace) or config.defaults.workspace end
function M.agentMaxSteps() return settings.get(config.settings.agentMaxSteps) or config.defaults.agentMaxSteps end
function M.defaultAgent() return settings.get(config.settings.defaultAgent) or config.defaults.defaultAgent end
function M.onboardingCompleted() return settings.get(config.settings.onboardingCompleted) or config.defaults.onboardingCompleted end
function M.rednetGatewayEnabled() return settings.get(config.settings.rednetGatewayEnabled) or config.defaults.rednetGatewayEnabled end
function M.serverName() return settings.get(config.settings.serverName) or config.defaults.serverName end
function M.authToken() return settings.get(config.settings.authToken) or config.defaults.authToken end
function M.remoteAuthStatus()
  local token = M.authToken()
  if token == nil or token == "" then return "locked" end
  return "auth-token"
end

return M
