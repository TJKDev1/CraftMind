package.path = "/?.lua;/?/init.lua;" .. package.path

local config = require("craftmind.config")
local settingsx = require("craftmind.core.settings")
local menu = require("craftmind.ui.menu")

settingsx.defineAll()

local providerItem = menu.choose("CraftMind Setup: Provider", {
  { label = "Groq", value = "groq" },
  { label = "Gemini", value = "gemini" },
  { label = "NVIDIA NIM", value = "nvidia" },
  { label = "OpenAI Compatible", value = "openai_compat" },
})
if not providerItem then return end
settingsx.set(config.settings.provider, providerItem.value)

local providerCfg = config.providers[providerItem.value]
local model = menu.prompt("Model", providerCfg.defaultModel or "")
settingsx.set(config.settings.model, model)

if providerItem.value == "groq" then
  settingsx.set(config.settings.groqKey, menu.prompt("Groq API key", settingsx.get(config.settings.groqKey) or ""))
elseif providerItem.value == "gemini" then
  settingsx.set(config.settings.geminiKey, menu.prompt("Gemini API key", settingsx.get(config.settings.geminiKey) or ""))
elseif providerItem.value == "nvidia" then
  settingsx.set(config.settings.nvidiaKey, menu.prompt("NVIDIA API key", settingsx.get(config.settings.nvidiaKey) or ""))
elseif providerItem.value == "openai_compat" then
  settingsx.set(config.settings.openaiCompatBaseUrl, menu.prompt("Base URL", settingsx.get(config.settings.openaiCompatBaseUrl) or ""))
  settingsx.set(config.settings.openaiCompatKey, menu.prompt("API key", settingsx.get(config.settings.openaiCompatKey) or ""))
end

local safety = menu.choose("Safety", {
  { label = "Safe multiplayer default", value = "safe" },
  { label = "Power mode raw Lua", value = "power" },
})
if safety then settingsx.set(config.settings.safety, safety.value) end

local profile = menu.choose("Profile", {
  { label = "Multiplayer", value = "multiplayer" },
  { label = "Singleplayer", value = "singleplayer" },
  { label = "Admin", value = "admin" },
})
if profile then settingsx.set(config.settings.profile, profile.value) end

local rawConfirm = menu.choose("Raw Lua confirmation", {
  { label = "Always confirm raw Lua previews", value = "always" },
  { label = "Optional", value = "optional" },
  { label = "Off", value = "off" },
})
if rawConfirm then settingsx.set(config.settings.rawLuaConfirm, rawConfirm.value) end

local workspace = menu.prompt("Agent workspace", settingsx.get(config.settings.workspace) or config.defaults.workspace)
settingsx.set(config.settings.workspace, workspace)

local maxSteps = tonumber(menu.prompt("Agent max steps", tostring(settingsx.get(config.settings.agentMaxSteps) or config.defaults.agentMaxSteps))) or config.defaults.agentMaxSteps
settingsx.set(config.settings.agentMaxSteps, maxSteps)

print("Setup complete.")
