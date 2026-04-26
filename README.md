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
- Multiplayer-safe defaults with explicit power mode opt-in
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
- Safe-by-default local and remote controls
- OpenClaw-style Agent Workspace with autonomous ReAct tool loops
- Runtime pipeline: `channel → route → context → model → tools → persist`
- OpenClaw-style bootstrap context (`AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`, `MEMORY.md`)
- Hatchable ComputerCraft agent identity (`soul.md`, `identity.md`, `tools.md`, `memory.md`, `inbox.md`)
- Persistent terminal session logs under `.craftmind/sessions/`
- Compact skill list with on-demand `SKILL.md` loading from `skills/` or `.craftmind/skills/`
- Optional multi-agent messaging/orchestration, with one default agent by default
- Dedicated workspace at `/craftmind/workspace` by default
- Optional power mode for raw Lua and shell execution
- Raw Lua preview and confirmation for chat raw-Lua flows
- OpenClaw-style docs manifest with workspace-readable mirrored docs
- OpenClaw-style Turtle Channel hub for auth-token setup, server startup, discovery, status, inventory, inspect, refuel, and gated raw Lua
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

Or run onboarding/setup/chat/agent directly:

```lua
craftmind/apps/setup.lua
craftmind/apps/chat.lua
craftmind/apps/agent.lua
craftmind/apps/agents.lua
craftmind/apps/turtle.lua
craftmind/apps/remote.lua
```

## Onboarding

CraftMind setup now follows the OpenClaw onboarding pattern, adapted to ComputerCraft:

1. Security warning and explicit acknowledgement.
2. Model provider and credentials.
3. Workspace selection and bootstrap file seeding.
4. Execution safety defaults.
5. User profile written to `USER.md`.
6. Agent hatching into `.craftmind/agents/<id>/`.
7. Optional advanced modules for docs mode, max steps, rednet/turtle gateway notes, and skill seeding.

Modes:

```lua
craftmind/apps/setup.lua --quickstart
craftmind/apps/setup.lua --advanced
craftmind/apps/setup.lua --repair
craftmind/apps/setup.lua --non-interactive --accept-risk --provider=groq --workspace=/craftmind/workspace --agent-id=main
```

Onboarding is modular in `craftmind/onboarding/init.lua`: each feature is a registered step with `id`, `title`, `modes`, `order`, and `run(state)`, so new setup features can be added without rewriting the whole flow.

## Hatching agents

Run `Agents / Hatch` from the menu or directly:

```lua
craftmind/apps/agents.lua
```

CraftMind creates OpenClaw-style workspace files plus default agent files:

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
    computercraft-quick-reference.md
    bundled/
      agents.md
      craftmind.md
      openclaw-adaptation.md
      tools.md
  .craftmind/sessions/
    terminal-main.jsonl
```

Bootstrap and identity files are included in chat and agent prompts. Docs are provided as a compact manifest by default, and the actual docs live inside the workspace so the agent can inspect them on demand with normal workspace tools. The agent can update local docs/memory/identity when you ask it to refine itself.

Multi-agent mode is optional. Agents can message each other with `<craftmind-message to="agent-id">...</craftmind-message>`; the default experience remains one agent.

## Safety

Default settings:

```txt
provider: groq
safety: safe
remote control: locked until auth token is set
raw lua confirm: always
```

Agent file/read/list/message tools stay inside its workspace. Shell and raw Lua tools are blocked unless safety is `power`; when enabled, they run with full ComputerCraft permissions from the workspace. External content, rednet messages, docs, and tool output are treated as untrusted. Remote turtle commands require a matching `craftmind.auth_token`; use `craftmind/apps/turtle.lua` or main-menu Turtle Channel to paste/generate the token and view exact server/client commands. A blank token locks remote control except discovery.

## Project layout

```txt
craftmind/
  apps/       setup and chat apps
  ai/         chat, runtime pipeline, workspace agent, and Lua execution logic
  client/     remote client helpers
  core/       settings, HTTP, logging
  docs/       docs manifest/RAG index and agent-visible markdown docs
  identity/   hatchable agent identity files and context loader
  providers/  AI provider adapters
  tools/      local tools such as file I/O
  turtle/     turtle server
  ui/         terminal UI helpers
```

## License

MIT. See `LICENSE`.
