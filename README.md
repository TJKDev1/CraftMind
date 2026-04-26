# CraftMind

CraftMind is a modular AI framework for ComputerCraft. It supports docs-aware chat, file creation, raw Lua power mode, and multiplayer-aware turtle control.

## Status

Early rewrite skeleton. Core modules exist, but APIs and UX may change.

## Features

- Modular AI providers
  - Groq
  - Gemini
  - NVIDIA NIM
  - OpenAI-compatible endpoints
- Safe-by-default multiplayer profile
- Optional power mode for raw Lua execution
- Raw Lua preview and confirmation
- Curated local ComputerCraft docs context
- Rednet turtle server skeleton
- Public GitHub installer

## Install

In ComputerCraft:

```lua
wget run https://raw.githubusercontent.com/TJKDev1/CraftMind/refs/heads/main/install.lua
```

If your repository name is different, edit `OWNER`, `REPO`, and `BRANCH` at top of `install.lua` before publishing.

## Run

```lua
/craftmind/boot.lua
```

Or run setup/chat directly:

```lua
craftmind/apps/setup.lua
craftmind/apps/chat.lua
```

## Safety

Default settings:

```txt
provider: groq
safety: safe
profile: multiplayer
raw lua confirm: always
```

Raw Lua execution is blocked unless safety is `power` or profile is `admin`. In multiplayer, set an auth token on turtle servers before remote execution.

## Project layout

```txt
craftmind/
  apps/       setup and chat apps
  ai/         chat and Lua execution logic
  client/     remote client helpers
  core/       settings, HTTP, logging
  docs/       curated docs index
  providers/  AI provider adapters
  tools/      local tools such as file I/O
  turtle/     turtle server
  ui/         terminal UI helpers
```

## License

MIT. See `LICENSE`.
