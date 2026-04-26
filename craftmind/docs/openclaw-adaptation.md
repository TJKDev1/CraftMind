# OpenClaw-style architecture in CraftMind

CraftMind keeps the product name CraftMind and adapts OpenClaw patterns to ComputerCraft/CC:Tweaked.

## OpenClaw baseline

OpenClaw uses three layers:

1. Channel — adapters normalize inbound messages from chat/control surfaces.
2. Brain — agent runtime assembles context, calls a model, runs a ReAct loop, loads skills, and persists state.
3. Body — tools perform real actions such as file operations, browser automation, messaging, and scheduled jobs.

OpenClaw message flow is commonly described as seven stages: normalize input, route/session serialize, assemble context, model inference, ReAct tool loop, on-demand skill loading, memory/persistence.

## CraftMind mapping

| OpenClaw concept | CraftMind / ComputerCraft fit |
| --- | --- |
| Channel layer | Terminal prompts now; rednet/turtle/http adapters can normalize events later. |
| Brain layer | Provider adapters, bootstrap files, identity files, docs context, skill list, session JSONL, workspace agent loop. |
| Body layer | Workspace list/read/write, agent messaging, shell/Lua behind power/admin, turtles/rednet as in-game actuators. |
| Browser automation | Out of scope; ComputerCraft-native turtle, rednet, peripheral, and terminal actions replace it. |
| Markdown workspace | `/craftmind/workspace` with `AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`, `MEMORY.md`. |
| Sessions | `.craftmind/sessions/*.jsonl`, recent turns loaded into Agent Workspace. |
| Skills | `skills/<skill>/SKILL.md` or `.craftmind/skills/<skill>/SKILL.md`; compact list injected, full file read on demand. |

## Onboarding adaptation

OpenClaw onboarding configures gateway, workspace, model/provider, channels, skills, and first-run agent bootstrapping. CraftMind mirrors that flow in ComputerCraft-native modules:

1. Security acknowledgement.
2. Provider/model/API key setup.
3. Workspace bootstrap file seeding.
4. Safety profile selection.
5. User profile capture into `USER.md`.
6. Agent hatching into `.craftmind/agents/<id>/`.
7. Optional gateway/channel setup for rednet/turtle server notes.
8. Optional skill template seeding.

The implementation is modular: `craftmind.onboarding` owns a step registry. Steps declare `id`, `title`, `order`, `modes`, optional `when(state)`, and `run(state)`. QuickStart, Advanced, Repair, and non-interactive modes select subsets of these steps. New onboarding features should be added as new steps instead of editing one long setup script.

## Safety deltas

ComputerCraft has no OS sandbox. CraftMind keeps file tools workspace-scoped and gates shell/raw Lua behind `safety=power` or `profile=admin`. External text from docs, rednet, files, and tool output is treated as untrusted and must not override operating rules.
