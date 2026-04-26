# CraftMind

CraftMind's goal is to bring the **OpenClaw idea to ComputerCraft**: an AI-first autonomous workspace agent with OpenClaw-style coding, file editing, command execution, and ComputerCraft/CC:Tweaked assistance inside Minecraft computers and turtles.

The name stays **CraftMind**. OpenClaw describes the product idea and agent style, not a rename.

## Mission and scope

Build a safe, useful OpenClaw-style agent experience for ComputerCraft:

- AI workspace agent as the primary product experience
- ComputerCraft-native Lua tooling and terminal UX
- Workspace-scoped file inspect/read/write tools
- Shell/Lua execution loops with explicit safety gates
- Docs-aware chat for ComputerCraft, turtles, rednet, and Lua
- Multiplayer-safe defaults with admin/power mode opt-in
- Modular provider support for Groq, Gemini, NVIDIA NIM, and OpenAI-compatible APIs

Out of scope for now: non-ComputerCraft desktop automation, browser automation, and general-purpose OS agents outside the ComputerCraft environment.

## Status

Early rewrite skeleton. Core modules exist, but APIs and UX may change while the OpenClaw-style ComputerCraft agent experience is built out.

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
