# CraftMind

CraftMind is a ComputerCraft implementation of the OpenClaw idea: an AI-first workspace agent that can understand ComputerCraft, inspect and edit files, run safe tool loops, and help automate computers and turtles.

The project name stays **CraftMind**. OpenClaw describes the idea, scope, and agent style.

## Goals

- Make the Agent Workspace the primary OpenClaw-style experience for ComputerCraft
- Keep the implementation ComputerCraft/CC:Tweaked-native
- Private-first project structure
- Multiplayer-safe defaults
- Autonomous tool loops for list/read/write/shell/Lua operations
- OpenClaw-style bootstrap context with `AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`, and `MEMORY.md`
- Hatchable agent identity with `soul.md`, `identity.md`, `tools.md`, `memory.md`, and `inbox.md`
- Persistent terminal sessions under `.craftmind/sessions/*.jsonl`
- Compact skill list with on-demand `SKILL.md` loading from `skills/` or `.craftmind/skills/`
- Optional multi-agent messaging/orchestration while keeping one default agent by default
- Power mode for raw Lua/shell execution when explicitly enabled
- Modular providers: Groq, Gemini, NVIDIA NIM, OpenAI-compatible APIs
- Curated bundled docs first, optional full ComputerCraft docs later
- Shared codebase with profiles instead of separate safe/unsafe versions

## AI scope for this codebase

AI contributors and in-app assistants should treat this project as:

> Build CraftMind as an OpenClaw-style agent for ComputerCraft, not a generic chatbot and not a desktop OS agent.

Prioritize ComputerCraft-native agent workflows, turtle/rednet use cases, Lua code generation, terminal UX, and safe workspace automation.

## Current skeleton

- `boot.lua` — main menu
- `apps/setup.lua` — OpenClaw-style onboarding entrypoint
- `apps/chat.lua` — docs-aware chat client
- `ui/render.lua` — colored terminal rendering for replies and thinking blocks
- `providers/` — provider abstraction
- `ai/lua_agent.lua` — raw Lua preview/confirm executor
- `ai/tool_runner.lua` — confirmed file write/append tool blocks
- `ai/context.lua` — OpenClaw-style bootstrap/context/skills assembler
- `ai/session.lua` — ComputerCraft-friendly session JSONL persistence
- `ai/workspace_agent.lua` — OpenClaw-style agent prompt loop
- `ai/workspace_tools.lua` — workspace file/read/list/shell/Lua tools
- `turtle/server.lua` — Rednet turtle server skeleton
- `client/remote.lua` — discovery/run client library
- `docs/index.lua` — curated local docs search plus markdown docs loader
- `docs/*.md` — CraftMind documentation visible to agents
- `identity/init.lua` — hatching, identity context, memory/inbox helpers
- `onboarding/init.lua` — modular QuickStart/Advanced/Repair/non-interactive setup steps
- `ai/orchestrator.lua` — agent-to-agent message/reply helper
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

## Onboarding

First boot offers OpenClaw-style onboarding. Direct modes:

```lua
craftmind/apps/setup.lua --quickstart
craftmind/apps/setup.lua --advanced
craftmind/apps/setup.lua --repair
craftmind/apps/setup.lua --non-interactive --accept-risk --provider=groq --workspace=/craftmind/workspace --agent-id=main
```

QuickStart configures provider/model, workspace, safe defaults, user profile, and agent. Advanced adds raw Lua confirmation, docs mode, max agent steps, rednet/turtle gateway notes, and optional skill seeding. New setup features should register a new step in `craftmind.onboarding`.

## Hatching and agent identity

Run:

```lua
craftmind/apps/agents.lua
```

Use `Hatch / activate agent` to give the assistant an id, a name, and a ComputerCraft-focused soul. CraftMind also creates OpenClaw-style workspace bootstrap files:

```txt
/craftmind/workspace/
  AGENTS.md
  SOUL.md
  USER.md
  TOOLS.md
  HEARTBEAT.md
  MEMORY.md
  .craftmind/agents/main/
    identity.md
    soul.md
    tools.md
    memory.md
    inbox.md
    orchestration.md
  .craftmind/docs/
    craftmind.md
    self-modification.md
  .craftmind/sessions/
    terminal-main.jsonl
```

Chat and Agent Workspace include these files as prompt context. The files are workspace-scoped, so the agent can read or modify its own bootstrap, identity, memory, and local docs through normal tools when asked. Multi-agent messaging is available with `<craftmind-message to="agent-id">...</craftmind-message>`, but the default flow is still one agent.

## Agent Workspace

Run from menu or directly:

```lua
craftmind/apps/agent.lua
```

Agent gets dedicated workspace (`/craftmind/workspace` by default). It can list/read/write workspace files and exchange agent messages in safe mode. Shell/Lua tool blocks are blocked unless safety is `power` or profile is `admin`.

## Safety defaults

Default mode is safe. Raw Lua and shell execution are blocked unless safety is `power` or profile is `admin`. Workspace file/list/read/message tools remain workspace-scoped. Preview + confirmation is enabled by default for chat raw-Lua flows.

For multiplayer servers, set `craftmind.auth_token` on turtle servers before remote execution.

## Provider notes

Groq, NVIDIA, and custom providers use OpenAI-compatible `/chat/completions`. Gemini uses Google `generateContent`.
