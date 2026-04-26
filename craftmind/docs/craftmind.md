# CraftMind documentation

CraftMind is the ComputerCraft implementation of the OpenClaw idea: an AI-first autonomous workspace agent for CC:Tweaked computers, turtles, pocket computers, and rednet networks.

The product name, package namespace, install path, settings, and XML tools stay `CraftMind` / `craftmind`. OpenClaw describes the interaction style only.

## Core rules

- Stay ComputerCraft-native: Lua, shell, fs, term, peripheral, rednet, turtles, and in-game constraints.
- Keep file/list/read/write tools workspace-scoped.
- Gate shell execution and raw Lua behind `safety=power` or `profile=admin`.
- Prefer small, inspectable steps over hidden automation.
- Default to one agent. Multi-agent orchestration is optional.

## Workspace

The default workspace is `/craftmind/workspace`. CraftMind creates OpenClaw-style bootstrap files at workspace root:

```txt
AGENTS.md
SOUL.md
USER.md
TOOLS.md
HEARTBEAT.md
MEMORY.md
```

Agent identity and hatching files live inside the workspace at:

```txt
.craftmind/agents/<agent-id>/
  identity.md
  soul.md
  tools.md
  memory.md
  inbox.md
  orchestration.md
```

Session logs live at `.craftmind/sessions/*.jsonl`. Skills live at `skills/<skill>/SKILL.md` or `.craftmind/skills/<skill>/SKILL.md`; CraftMind injects a compact skill list and expects agents to read the full skill on demand.

CraftMind also creates workspace-local docs at `.craftmind/docs/` so agents can keep ComputerCraft-specific project guidance close to the workspace.

Because these files are inside the workspace, an agent can inspect or modify its own bootstrap/identity/docs/memory with normal workspace tools when the user asks it to refine itself.
