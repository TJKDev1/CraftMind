local config = require("craftmind.config")
local settingsx = require("craftmind.core.settings")
local compat = require("craftmind.providers.openai_compat")

local M = {}

function M.chat(opts)
  opts = opts or {}
  opts.baseUrl = config.providers.nvidia.baseUrl
  opts.apiKey = settingsx.get(config.settings.nvidiaKey)
  opts.model = opts.model or settingsx.model() or config.providers.nvidia.defaultModel
  return compat.chat(opts)
end

return M
