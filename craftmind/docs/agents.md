# CraftMind agents

A CraftMind agent is a ComputerCraft-focused assistant identity backed by markdown files. The default agent is `main`; users can hatch more agents later.

## Hatching

Hatching means creating an agent identity through conversation:

1. Pick an agent id, such as `main`, `miner`, `librarian`, or `rednet-tech`.
2. Give it a display name.
3. Give it a soul: a short ComputerCraft-oriented personality and purpose.
4. CraftMind writes identity files under `.craftmind/agents/<id>/`.
5. The agent receives those files as prompt context in chat and workspace agent mode.

## Workspace bootstrap files

CraftMind also creates OpenClaw-style workspace root files:

- `AGENTS.md` — operating rules, safety boundaries, and architecture mapping.
- `SOUL.md` — global persona/tone for CraftMind.
- `USER.md` — user/environment preferences.
- `TOOLS.md` — tool conventions and XML block syntax.
- `HEARTBEAT.md` — future periodic task checklist.
- `MEMORY.md` — durable workspace memory.

These files are injected before inference. They are plain Markdown so users and agents can inspect or refine behavior safely.

## Identity files

- `identity.md` — name, id, home path, creation note.
- `soul.md` — per-agent personality, purpose, and constraints.
- `tools.md` — per-agent tool notes.
- `memory.md` — per-agent durable notes worth keeping.
- `inbox.md` — user and agent-to-agent messages.
- `orchestration.md` — local conventions for multi-agent work.

## Sessions

Agent Workspace writes terminal session history to `.craftmind/sessions/terminal-<agent>.jsonl` and reloads recent turns. This mimics OpenClaw session persistence in a ComputerCraft-friendly file format.

## Multi-agent orchestration

Agents can send each other messages with:

```xml
<craftmind-message to="agent-id">
Please inspect this design and suggest turtle-safe improvements.
</craftmind-message>
```

The receiving agent gets the message in `inbox.md` and may produce a reply. Keep delegated tasks short, explicit, and safe. Do not delegate shell or raw Lua execution unless the user has intentionally enabled power/admin mode.
