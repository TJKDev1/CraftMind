package.path = "/?.lua;/?/init.lua;" .. package.path

local onboarding = require("craftmind.onboarding")
local render = require("craftmind.ui.render")

local args = { ... }
local ok, err = onboarding.run(args)
if not ok then
  render.error(err)
end
