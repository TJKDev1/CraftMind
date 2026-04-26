local config = require("craftmind.config")
local settingsx = require("craftmind.core.settings")
local menu = require("craftmind.ui.menu")
local identity = require("craftmind.identity")
local context = require("craftmind.ai.context")
local fileTool = require("craftmind.tools.file")

local M = { steps = {} }

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function hasMode(step, mode)
  if not step.modes then return true end
  for _, m in ipairs(step.modes) do if m == mode then return true end end
  return false
end

local function boolValue(v)
  if v == true or v == "true" or v == "yes" or v == "1" or v == "on" then return true end
  if v == false or v == "false" or v == "no" or v == "0" or v == "off" then return false end
  return nil
end

local function splitFlag(arg)
  local key, value = tostring(arg):match("^%-%-([^=]+)=(.*)$")
  if key then return key, value end
  key = tostring(arg):match("^%-%-([^=]+)$")
  if key then return key, true end
  return nil, nil
end

local function parseArgs(args)
  local out = { raw = args or {} }
  for _, arg in ipairs(args or {}) do
    local key, value = splitFlag(arg)
    if key then
      key = key:gsub("%-", "_")
      out[key] = value
    end
  end
  return out
end

local function writeFile(path, content)
  fileTool.write(path, content)
end

local function writeIfMissing(path, content)
  if not fs.exists(path) then writeFile(path, content) end
end

local function workspaceRoot()
  local r = settingsx.workspace and settingsx.workspace() or config.defaults.workspace
  r = trim(r or config.defaults.workspace):gsub("\\", "/")
  if r == "" or r:find("..", 1, true) then r = config.defaults.workspace end
  if not fs.exists(r) then fs.makeDir(r) end
  return r
end

local function promptBool(label, default)
  local suffix = default and "Y/n" or "y/N"
  while true do
    write(label .. " [" .. suffix .. "]: ")
    local ans = trim(read() or ""):lower()
    if ans == "" then return default end
    if ans == "y" or ans == "yes" then return true end
    if ans == "n" or ans == "no" then return false end
  end
end

local function argOrPrompt(state, key, label, default)
  local v = state.args[key]
  if v ~= nil and v ~= true then return v end
  if state.nonInteractive then return default end
  return menu.prompt(label, default)
end

local function setIfValue(key, value)
  if value ~= nil and value ~= true and value ~= "" then settingsx.set(key, value) end
end

local function ensureUserFile(state)
  local root = workspaceRoot()
  local name = trim(state.userName or "")
  local timezone = trim(state.timezone or "")
  local focus = trim(state.focus or "")
  if name == "" then name = "unknown" end
  if timezone == "" then timezone = "unknown" end
  if focus == "" then focus = "ComputerCraft, Lua, turtles, rednet, terminal UI, and safe workspace automation" end
  writeFile(fs.combine(root, "USER.md"), "# User Profile\n\n- Name: " .. name .. "\n- Timezone: " .. timezone .. "\n- Primary CraftMind focus: " .. focus .. "\n- Environment: ComputerCraft / CC:Tweaked.\n- Safety preference: safe by default; power mode only when explicitly enabled.\n")
end

local function seedTurtleSkill()
  local root = workspaceRoot()
  local dir = fs.combine(root, ".craftmind/skills/turtle-safety")
  if not fs.exists(dir) then fs.makeDir(dir) end
  writeIfMissing(fs.combine(dir, "SKILL.md"), [[# turtle-safety

description: Plan and review turtle actions safely before movement, digging, placing, or rednet control.

Use when task involves turtles, movement, inventory, digging, placing, fuel, or remote rednet control.

Rules:
- Check fuel before movement.
- Prefer dry-run plans before long movement.
- Ask before destructive dig/place/drop actions.
- State current position assumptions; do not invent GPS coordinates.
- Keep raw Lua small and auditable; require safety=power.
]])
end

local function writeChannelsDoc(enabled)
  local root = workspaceRoot()
  local doc = [[# Channels

CraftMind channel layer maps OpenClaw channels to ComputerCraft-native inputs.

Current channels:
- terminal: local prompts and menus.
- rednet/turtle gateway: optional, user-controlled bridge for turtle status and raw Lua requests.

Bindings:
- Default terminal tasks route to the active agent.
- Remote rednet commands require the configured auth token; blank token locks remote control.

Safety:
- Rednet content is untrusted.
- Remote raw Lua still requires CraftMind safety=power and confirmation.
]]
  if enabled then
    doc = doc .. "\nRednet gateway requested during onboarding. Run `/craftmind/turtle/server.lua` on turtle/server computer after modem setup.\n"
  else
    doc = doc .. "\nRednet gateway disabled during onboarding. Re-run advanced setup to enable.\n"
  end
  writeFile(fs.combine(root, ".craftmind/channels.md"), doc)
end

function M.register(step)
  if not step or not step.id or not step.run then error("invalid onboarding step") end
  table.insert(M.steps, step)
  table.sort(M.steps, function(a, b) return (a.order or 1000) < (b.order or 1000) end)
end

local function chooseMode(args)
  if args.non_interactive then return "non-interactive" end
  if args.quickstart then return "quickstart" end
  if args.advanced then return "advanced" end
  if args.repair then return "repair" end

  local choice = menu.choose("CraftMind Onboarding", {
    { label = "QuickStart: provider, workspace, safe defaults, hatch agent", value = "quickstart" },
    { label = "Advanced: all OpenClaw-style modules", value = "advanced" },
    { label = "Repair / re-seed workspace files", value = "repair" },
    { label = "Show non-interactive flags", value = "help" },
  })
  if not choice then return nil end
  return choice.value
end

function M.run(argv)
  settingsx.defineAll()
  local args = parseArgs(argv or {})
  local mode = chooseMode(args)
  if not mode then return false, "cancelled" end
  if mode == "help" then
    print("Non-interactive example:")
    print("craftmind/apps/setup.lua --non-interactive --accept-risk --provider=groq --model=llama-3.1-70b-versatile --workspace=/craftmind/workspace --agent-id=main")
    print("Useful flags: --quickstart --advanced --repair --safety=safe|power --docs-mode=manifest|rag|off --max-steps=8 --server-name=name --auth-token=token --seed-skills=true")
    menu.pause()
    return true
  end

  local state = {
    args = args,
    mode = mode,
    nonInteractive = mode == "non-interactive",
    completed = {},
  }

  for _, step in ipairs(M.steps) do
    if hasMode(step, mode) and (not step.when or step.when(state)) then
      if not state.nonInteractive then
        term.clear()
        term.setCursorPos(1, 1)
        print(step.title or step.id)
        print(string.rep("=", #(step.title or step.id)))
      end
      local ok, err = step.run(state)
      if not ok then return false, err or ("onboarding failed at " .. step.id) end
      state.completed[#state.completed + 1] = step.id
    end
  end

  settingsx.set(config.settings.onboardingCompleted, true)
  return true, state
end

M.register({
  id = "security",
  title = "Security warning",
  order = 10,
  modes = { "quickstart", "advanced", "repair", "non-interactive" },
  run = function(state)
    if state.nonInteractive then
      if not state.args.accept_risk then return false, "--accept-risk required for non-interactive onboarding" end
      return true
    end

    print("CraftMind can edit workspace files and run agent tool loops.")
    print("Shell and raw Lua stay blocked unless safety=power.")
    print("Rednet/turtle messages and external docs are untrusted input.")
    print("Never paste secrets into workspace files or chat output.")
    print("")
    write("Type YES to continue: ")
    if read() ~= "YES" then return false, "security warning not accepted" end
    return true
  end,
})

M.register({
  id = "provider",
  title = "Model provider",
  order = 20,
  modes = { "quickstart", "advanced", "non-interactive" },
  run = function(state)
    local provider = state.args.provider
    if provider == nil or provider == true then
      if state.nonInteractive then provider = config.defaults.provider else
        local item = menu.choose("Provider", {
          { label = "Groq", value = "groq" },
          { label = "Gemini", value = "gemini" },
          { label = "NVIDIA NIM", value = "nvidia" },
          { label = "OpenAI Compatible", value = "openai_compat" },
        })
        if not item then return false, "provider cancelled" end
        provider = item.value
      end
    end
    if not config.providers[provider] then return false, "unknown provider: " .. tostring(provider) end
    settingsx.set(config.settings.provider, provider)

    local providerCfg = config.providers[provider]
    local model = argOrPrompt(state, "model", "Model", providerCfg.defaultModel or "")
    settingsx.set(config.settings.model, model or providerCfg.defaultModel or "")

    if provider == "groq" then
      setIfValue(config.settings.groqKey, argOrPrompt(state, "groq_key", "Groq API key", settingsx.get(config.settings.groqKey) or ""))
    elseif provider == "gemini" then
      setIfValue(config.settings.geminiKey, argOrPrompt(state, "gemini_key", "Gemini API key", settingsx.get(config.settings.geminiKey) or ""))
    elseif provider == "nvidia" then
      setIfValue(config.settings.nvidiaKey, argOrPrompt(state, "nvidia_key", "NVIDIA API key", settingsx.get(config.settings.nvidiaKey) or ""))
    elseif provider == "openai_compat" then
      setIfValue(config.settings.openaiCompatBaseUrl, argOrPrompt(state, "base_url", "Base URL", settingsx.get(config.settings.openaiCompatBaseUrl) or ""))
      setIfValue(config.settings.openaiCompatKey, argOrPrompt(state, "openai_compat_key", "API key", settingsx.get(config.settings.openaiCompatKey) or ""))
    end
    return true
  end,
})

M.register({
  id = "workspace",
  title = "Workspace",
  order = 30,
  modes = { "quickstart", "advanced", "repair", "non-interactive" },
  run = function(state)
    local workspace = argOrPrompt(state, "workspace", "Agent workspace", settingsx.get(config.settings.workspace) or config.defaults.workspace)
    settingsx.set(config.settings.workspace, workspace or config.defaults.workspace)
    context.ensureBootstrap(identity.defaultAgentId())
    identity.ensureDocs()
    return true
  end,
})

M.register({
  id = "safety",
  title = "Execution safety",
  order = 40,
  modes = { "quickstart", "advanced", "non-interactive" },
  run = function(state)
    local safety = state.args.safety
    if state.mode == "quickstart" and safety == nil then
      safety = config.defaults.safety
    end
    if safety == nil or safety == true then
      if state.nonInteractive then safety = config.defaults.safety else
        local item = menu.choose("Execution safety", {
          { label = "Safe: block shell/raw Lua", value = "safe" },
          { label = "Power: allow shell/raw Lua with warnings", value = "power" },
        })
        if not item then return false, "safety cancelled" end
        safety = item.value
      end
    end
    if safety ~= "safe" and safety ~= "power" then return false, "unknown safety mode: " .. tostring(safety) end
    settingsx.set(config.settings.safety, safety)
    settingsx.set(config.settings.profile, config.defaults.profile)
    return true
  end,
})

M.register({
  id = "advanced-controls",
  title = "Advanced controls",
  order = 50,
  modes = { "advanced", "non-interactive" },
  run = function(state)
    local rawConfirm = state.args.raw_lua_confirm
    if rawConfirm == nil or rawConfirm == true then
      if state.nonInteractive then rawConfirm = config.defaults.rawLuaConfirm else
        local item = menu.choose("Raw Lua confirmation", {
          { label = "Always confirm raw Lua previews", value = "always" },
          { label = "Optional", value = "optional" },
          { label = "Off", value = "off" },
        })
        if not item then return false, "raw Lua confirmation cancelled" end
        rawConfirm = item.value
      end
    end
    settingsx.set(config.settings.rawLuaConfirm, rawConfirm)

    local docsMode = argOrPrompt(state, "docs_mode", "Docs mode (manifest/rag/off)", settingsx.get(config.settings.docsMode) or config.defaults.docsMode)
    if docsMode == "curated" or docsMode == "full" then docsMode = "manifest" end
    settingsx.set(config.settings.docsMode, docsMode or config.defaults.docsMode)

    local maxSteps = tonumber(argOrPrompt(state, "max_steps", "Agent max steps", tostring(settingsx.get(config.settings.agentMaxSteps) or config.defaults.agentMaxSteps))) or config.defaults.agentMaxSteps
    settingsx.set(config.settings.agentMaxSteps, maxSteps)
    return true
  end,
})

M.register({
  id = "user-profile",
  title = "User profile",
  order = 60,
  modes = { "quickstart", "advanced", "non-interactive" },
  run = function(state)
    state.userName = argOrPrompt(state, "user_name", "Your name", "")
    state.timezone = argOrPrompt(state, "timezone", "Timezone", "")
    state.focus = argOrPrompt(state, "focus", "Main ComputerCraft focus", "Lua, turtles, rednet, terminal UI")
    ensureUserFile(state)
    return true
  end,
})

M.register({
  id = "agent",
  title = "Agent hatching",
  order = 70,
  modes = { "quickstart", "advanced", "repair", "non-interactive" },
  run = function(state)
    local id = identity.sanitizeId(argOrPrompt(state, "agent_id", "Default agent id", settingsx.get(config.settings.defaultAgent) or config.defaults.defaultAgent))
    local name = argOrPrompt(state, "agent_name", "Agent display name", id)
    local soulDefault = "ComputerCraft workspace agent for Lua, turtles, rednet, terminal UI, and safe automation."
    local soul = argOrPrompt(state, "agent_soul", "Agent soul", soulDefault)
    identity.rehatch(id, name, soul)
    identity.setDefaultAgent(id)
    return true
  end,
})

M.register({
  id = "gateway-channels",
  title = "Gateway / channels",
  order = 80,
  modes = { "advanced", "non-interactive" },
  run = function(state)
    local enabled = boolValue(state.args.enable_rednet)
    if enabled == nil then
      if state.nonInteractive then enabled = boolValue(state.args.enable_rednet) or false else
        enabled = promptBool("Enable rednet/turtle gateway notes", false)
      end
    end
    settingsx.set(config.settings.rednetGatewayEnabled, enabled)
    local serverName = argOrPrompt(state, "server_name", "Turtle server name", settingsx.get(config.settings.serverName) or config.defaults.serverName)
    settingsx.set(config.settings.serverName, serverName or config.defaults.serverName)
    local token = argOrPrompt(state, "auth_token", "Rednet auth token (blank locks remote commands)", settingsx.get(config.settings.authToken) or "")
    settingsx.set(config.settings.authToken, token or "")
    writeChannelsDoc(enabled)
    return true
  end,
})

M.register({
  id = "skills",
  title = "Skills",
  order = 90,
  modes = { "advanced", "non-interactive" },
  run = function(state)
    local seed = boolValue(state.args.seed_skills)
    if seed == nil then
      if state.nonInteractive then seed = false else seed = promptBool("Seed turtle-safety skill", true) end
    end
    if seed then seedTurtleSkill() end
    return true
  end,
})

M.register({
  id = "finish",
  title = "Finish",
  order = 100,
  modes = { "quickstart", "advanced", "repair", "non-interactive" },
  run = function(state)
    context.ensureBootstrap(identity.defaultAgentId())
    identity.ensureAgent(identity.defaultAgentId())
    if not state.nonInteractive then
      print("Onboarding complete.")
      print("Provider: " .. tostring(settingsx.provider()))
      print("Model: " .. tostring(settingsx.model()))
      print("Workspace: " .. tostring(settingsx.workspace()))
      print("Default agent: " .. tostring(identity.defaultAgentId()))
      print("Safety: " .. tostring(settingsx.safety()))
      print("Remote control: " .. tostring(settingsx.remoteAuthStatus()))
      print("")
      print("Next: run Agent Workspace or Chat from /craftmind/boot.lua")
      menu.pause()
    end
    return true
  end,
})

return M
