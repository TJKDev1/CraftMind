# CraftMind

CraftMind is a modular AI framework for ComputerCraft. It supports docs-aware chat, file creation, OpenClaw-style workspace agent mode, raw Lua power mode, and multiplayer-aware turtle control.

## Status

Early rewrite skeleton. Core modules exist, but APIs and UX may change.

## Features

- Modular AI providers
  - Groq
  - Gemini
  - NVIDIA NIM
  - OpenAI-compatible endpoints
- Safe-by-default multiplayer profile
- OpenClaw-style Agent Workspace with autonomous tool loops
- Dedicated workspace at `/craftmind/workspace` by default
- Optional power mode for raw Lua and shell execution
- Raw Lua preview and confirmation for chat raw-Lua flows
- Curated local ComputerCraft docs context
- Rednet turtle server skeleton
- Public GitHub installer

## Install / Update

In ComputerCraft:

```lua
wget run https://raw.githubusercontent.com/TJKDev1/CraftMind/main/install.lua?bust=1
```

Installer detects fresh install, update, reinstall, and repair by reading `/craftmind/manifest.lua`.

## Run

```lua
/craftmind/boot.lua
```

Or run setup/chat/agent directly:

```lua
craftmind/apps/setup.lua
craftmind/apps/chat.lua
craftmind/apps/agent.lua
```

## Safety

Default settings:

```txt
provider: groq
safety: safe
profile: multiplayer
raw lua confirm: always
```

Raw Lua and agent execution are blocked unless safety is `power` or profile is `admin`. Agent file/read/list tools stay inside its workspace; shell/Lua tools run with full ComputerCraft permissions from that workspace. In multiplayer, set an auth token on turtle servers before remote execution.

## Project layout

```txt
craftmind/
  apps/       setup and chat apps
  ai/         chat, workspace agent, and Lua execution logic
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
