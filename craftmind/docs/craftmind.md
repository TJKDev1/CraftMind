# CraftMind documentation

CraftMind is the ComputerCraft implementation of the OpenClaw idea: an AI-first autonomous workspace agent for CC:Tweaked computers, turtles, pocket computers, and rednet networks.

The product name, package namespace, install path, settings, and XML tools stay `CraftMind` / `craftmind`. OpenClaw describes the interaction style only.

## Core rules

- Stay ComputerCraft-native: Lua, shell, fs, term, peripheral, rednet, turtles, and in-game constraints.
- Keep file/list/read/write tools workspace-scoped.
- Gate shell execution and raw Lua behind `safety=power` or `profile=admin`.
- Prefer small, inspectable steps over hidden automation.
- Default to one agent. Multi-agent orchestration is optional.

## Onboarding

Run `craftmind/apps/setup.lua` or choose **Onboarding / Setup** from boot. The flow mirrors OpenClaw but stays ComputerCraft-native:

- QuickStart configures provider/model, workspace, safe defaults, user profile, and default agent.
- Advanced adds raw Lua confirmation, docs mode, max agent steps, rednet/turtle gateway notes, and skill seeding.
- Repair re-seeds workspace bootstrap and agent files.
- Non-interactive mode supports flags such as `--non-interactive --accept-risk --provider=groq --workspace=/craftmind/workspace --agent-id=main`.

Onboarding features are registered as modular steps in `craftmind.onboarding`, making future setup features easy to add.

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
