local config = require("craftmind.config")
local settingsx = require("craftmind.core.settings")

local M = {}

function M.current()
  local name = settingsx.provider()
  if name == "groq" then return require("craftmind.providers.groq"), name end
  if name == "gemini" then return require("craftmind.providers.gemini"), name end
  if name == "nvidia" then return require("craftmind.providers.nvidia"), name end
  if name == "openai_compat" then
    local compat = require("craftmind.providers.openai_compat")
    local wrapper = {}
    function wrapper.chat(opts)
      opts = opts or {}
      opts.baseUrl = settingsx.get(config.settings.openaiCompatBaseUrl)
      opts.apiKey = settingsx.get(config.settings.openaiCompatKey)
      opts.model = opts.model or settingsx.model()
      return compat.chat(opts)
    end
    return wrapper, name
  end
  error("unknown provider: " .. tostring(name))
end

function M.chat(messages, opts)
  local provider = M.current()
  opts = opts or {}
  opts.messages = messages
  return provider.chat(opts)
end

return M
