local config = require("craftmind.config")
local settingsx = require("craftmind.core.settings")
local compat = require("craftmind.providers.openai_compat")

local M = {}

function M.chat(opts)
  opts = opts or {}
  opts.baseUrl = config.providers.groq.baseUrl
  opts.apiKey = settingsx.get(config.settings.groqKey)
  opts.model = opts.model or settingsx.model() or config.providers.groq.defaultModel
  return compat.chat(opts)
end

return M
