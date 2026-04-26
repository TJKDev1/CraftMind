local config = {
  name = "CraftMind",
  version = "0.3.4",
  namespace = "craftmind",
  mission = "Build the OpenClaw idea for ComputerCraft: an AI-first ComputerCraft workspace agent.",

  defaults = {
    provider = "groq",
    safety = "safe", -- safe | power; only power unlocks shell/raw Lua
    rawLuaConfirm = "always", -- always | optional | off
    profile = "multiplayer", -- legacy; no longer controls permissions
    docsMode = "manifest", -- manifest | rag | off (legacy curated/full are treated as manifest)
    workspace = "/craftmind/workspace",
    agentMaxSteps = 8,
    defaultAgent = "main",
    onboardingCompleted = false,
    rednetGatewayEnabled = false,
    serverName = "CraftMind Turtle",
    authToken = "",
  },

  settings = {
    provider = "craftmind.provider",
    model = "craftmind.model",
    safety = "craftmind.safety",
    profile = "craftmind.profile",
    rawLuaConfirm = "craftmind.raw_lua_confirm",
    docsMode = "craftmind.docs_mode",
    workspace = "craftmind.workspace",
    agentMaxSteps = "craftmind.agent_max_steps",
    defaultAgent = "craftmind.default_agent",
    onboardingCompleted = "craftmind.onboarding.completed",
    rednetGatewayEnabled = "craftmind.rednet_gateway.enabled",
    serverName = "craftmind.server_name",
    authToken = "craftmind.auth_token",

    groqKey = "craftmind.api_key.groq",
    geminiKey = "craftmind.api_key.gemini",
    nvidiaKey = "craftmind.api_key.nvidia",
    openaiCompatKey = "craftmind.api_key.openai_compat",
    openaiCompatBaseUrl = "craftmind.base_url.openai_compat",
  },

  providers = {
    groq = {
      label = "Groq",
      baseUrl = "https://api.groq.com/openai/v1",
      defaultModel = "llama-3.1-70b-versatile",
    },
    nvidia = {
      label = "NVIDIA NIM",
      baseUrl = "https://integrate.api.nvidia.com/v1",
      defaultModel = "meta/llama-3.1-70b-instruct",
    },
    gemini = {
      label = "Gemini",
      defaultModel = "models/gemini-1.5-flash",
    },
    openai_compat = {
      label = "OpenAI Compatible",
      baseUrl = "",
      defaultModel = "",
    },
  },
}

return config
