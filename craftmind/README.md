# CraftMind

Modular ComputerCraft AI framework for chat, docs-aware help, file creation, and turtle control.

## Goals

- Private-first project structure
- Multiplayer-safe defaults
- Power mode for raw Lua execution when explicitly enabled
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
- `turtle/server.lua` — Rednet turtle server skeleton
- `client/remote.lua` — discovery/run client library
- `docs/index.lua` — curated local docs search
- `tools/file.lua` — file read/write helper

## Install from public GitHub

Set `OWNER`, `REPO`, and `BRANCH` at top of root `install.lua`, then publish repo. In ComputerCraft:

```lua
wget run https://raw.githubusercontent.com/TJKDev1/CraftMind/main/install.lua
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
```

## Safety defaults

Default mode is safe. Raw Lua execution is blocked unless safety is `power` or profile is `admin`. Preview + confirmation is enabled by default.

For multiplayer servers, set `craftmind.auth_token` on turtle servers before remote execution.

## Provider notes

Groq, NVIDIA, and custom providers use OpenAI-compatible `/chat/completions`. Gemini uses Google `generateContent`.
