# AI Agent Scope

This repository is **CraftMind**.

Its mission is to implement the **OpenClaw idea for ComputerCraft**: an AI-first autonomous workspace agent for ComputerCraft/CC:Tweaked.

Keep the name `CraftMind` for the project, package namespace, install path, settings, and user-facing app identity.

## Priorities

1. Build CraftMind as an OpenClaw-style autonomous workspace agent for ComputerCraft/CC:Tweaked.
2. Keep behavior ComputerCraft-native: Lua, shell, turtles, rednet, terminal UI, and in-game constraints.
3. Make agent workflows clear, inspectable, and safe by default.
4. Preserve workspace path restrictions for file/list/read/write tools.
5. Gate shell and raw Lua execution behind `safety=power`.
6. Improve docs-aware chat only when it supports the OpenClaw-style ComputerCraft agent mission.

## Non-goals for now

- Generic desktop automation outside ComputerCraft
- Browser automation
- Host OS agents unrelated to ComputerCraft
- Removing safety gates to make demos easier

## Naming note

Do not rename CraftMind to OpenClaw. Use OpenClaw only to describe the idea, scope, and interaction style. Existing module paths, settings keys, and XML tool tags should remain `craftmind`.
