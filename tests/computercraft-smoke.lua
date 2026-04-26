local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
settingsx.defineAll()
settingsx.set(config.settings.workspace, "/workspace")

local tools = require("craftmind.ai.workspace_tools")
assert(type(tools.root()) == "string", "workspace root missing")
assert(tools.root() ~= "", "workspace root empty")

local identity = require("craftmind.identity")
local id = identity.ensureAgent("test-smoke")
assert(id == "test-smoke", "identity.ensureAgent returned wrong id")
assert(fs.exists(fs.combine(tools.root(), ".craftmind/agents/test-smoke/identity.md")), "identity file missing")

local context = require("craftmind.ai.context")
local ctx = context.bootstrapContext("test-smoke")
assert(ctx:find("AGENTS.md", 1, true), "bootstrap context missing AGENTS.md")
assert(fs.exists(fs.combine(tools.root(), "AGENTS.md")), "AGENTS.md missing")
assert(type(context.skillsContext()) == "string", "skillsContext did not return string")

local session = require("craftmind.ai.session")
assert(session.append("smoke", "user", "hello"), "session append failed")
local recent = session.recent("smoke", 1)
assert(#recent == 1, "session recent failed")
assert(recent[1].role == "user", "session role mismatch")
assert(recent[1].content == "hello", "session content mismatch")

local ops = tools.extract([[<craftmind-list path="." />]])
assert(#ops == 1 and ops[1].type == "list", "tool extract failed")
local ok, result = tools.run(ops[1])
assert(ok, "tool list failed: " .. tostring(result))


print("CraftMind ComputerCraft smoke OK")
