# CraftMind workspace tools

CraftMind agents request actions by emitting exact XML blocks. The app parses the blocks, runs allowed tools, appends observations to session history, and sends observations back to the model.

## Workspace-scoped tools

```xml
<craftmind-list path="." />
<craftmind-read path="relative/file.lua" />
<craftmind-file path="relative/file.lua" mode="write">
-- full file contents
</craftmind-file>
<craftmind-replace path="relative/file.lua">
<old>
exact old text
</old>
<new>
exact new text
</new>
</craftmind-replace>
```

Paths are relative to the workspace. Parent paths (`..`) are rejected. Absolute-looking paths are treated as workspace-relative by stripping the leading slash. `craftmind-replace` requires one exact match by default; add `count="all"` only when a broad replacement is intended.

## Power tools

```xml
<craftmind-exec command="ls" />
<craftmind-lua>
print("hi")
</craftmind-lua>
```

Shell and raw Lua require `safety=power`. They run from the workspace directory but have full ComputerCraft permissions, so they must be small and auditable.

## Skills

Skills may be added as folders containing `SKILL.md` under workspace `skills/` or `.craftmind/skills/`. CraftMind injects only a compact skill list; agents should read the relevant `SKILL.md` on demand before using a skill.

## Agent messaging

```xml
<craftmind-message to="agent-id">
Question or task for another CraftMind agent.
</craftmind-message>
```

Messaging writes to the target agent inbox and can request a reply through the orchestrator.

## Turtle channel tools

```xml
<craftmind-turtle action="discover" />
<craftmind-turtle action="status" id="12" />
<craftmind-turtle action="inventory" id="12" />
<craftmind-turtle action="inspect" id="12" direction="forward" />
<craftmind-turtle action="select" id="12" slot="1" />
<craftmind-turtle action="refuel" id="12" count="1" />
<craftmind-turtle action="run_lua" id="12">
print("hi")
</craftmind-turtle>
```

Turtle tools use Rednet protocol `craftmind.v1` and the configured `craftmind.auth_token`; discovery works without a token, all other actions require a matching token on client and server. Remote raw Lua requires `safety=power` locally and on the server, then server-side preview/confirmation. Agents should use `discover -> status -> inspect -> act`, and ask before movement, digging, placing, dropping, or destructive remote Lua.
