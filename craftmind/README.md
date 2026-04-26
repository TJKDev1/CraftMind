# CraftMind

Modular ComputerCraft AI framework for chat, docs-aware help, file creation, OpenClaw-style workspace agent mode, and turtle control.

## Goals

- Private-first project structure
- Multiplayer-safe defaults
- OpenClaw-style Agent Workspace with autonomous tool loops
- Power mode for raw Lua/shell execution when explicitly enabled
- Modular providers: Groq, Gemini, NVIDIA NIM, OpenAI-compatible APIs
- Curated bundled docs first, optional full ComputerCraft docs later
- Shared codebase with profiles instead of separate safe/unsafe versions

## Current skeleton

- `boot.lua` — main menu
- `apps/setup.lua` — provider/model/safety setup wizard
- `apps/chat.lua` — docs-aware chat client
- `ui/render.lua` — colored terminal rendering for replies and thinking blocks
- `providers/` — provider abstraction
- `ai/lua_agent.lua` — raw Lua preview/confirm executor
- `ai/tool_runner.lua` — confirmed file write/append tool blocks
- `ai/workspace_agent.lua` — OpenClaw-style agent prompt loop
- `ai/workspace_tools.lua` — workspace file/read/list/shell/Lua tools
- `turtle/server.lua` — Rednet turtle server skeleton
- `client/remote.lua` — discovery/run client library
- `docs/index.lua` — curated local docs search
- `tools/file.lua` — file read/write helper

## Install / Update from public GitHub

Installer detects fresh install, update, reinstall, and repair by reading `/craftmind/manifest.lua`. In ComputerCraft:

```lua
wget run https://raw.githubusercontent.com/TJKDev1/CraftMind/main/install.lua?bust=1
```

## Run in ComputerCraft

After install:

```lua
/craftmind/boot.lua
```

Or:

```lua
craftmind/apps/setup.lua
craftmind/apps/chat.lua
craftmind/apps/agent.lua
```

## Agent Workspace

Run from menu or directly:

```lua
craftmind/apps/agent.lua
```

Agent gets dedicated workspace (`/craftmind/workspace` by default). It can list/read/write workspace files and auto-run shell/Lua tool blocks. Execution is blocked unless safety is `power` or profile is `admin`.

## Safety defaults

Default mode is safe. Raw Lua and agent execution are blocked unless safety is `power` or profile is `admin`. Preview + confirmation is enabled by default for chat raw-Lua flows.

For multiplayer servers, set `craftmind.auth_token` on turtle servers before remote execution.

## Provider notes

Groq, NVIDIA, and custom providers use OpenAI-compatible `/chat/completions`. Gemini uses Google `generateContent`.
