local config = {
  name = "CraftMind",
  version = "0.2.0",

  defaults = {
    provider = "groq",
    safety = "safe", -- safe | power
    rawLuaConfirm = "always", -- always | optional | off
    profile = "multiplayer", -- multiplayer | singleplayer | admin
    docsMode = "curated", -- curated | full | off
    workspace = "/craftmind/workspace",
    agentMaxSteps = 8,
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
