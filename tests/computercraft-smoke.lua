local settingsx = require("craftmind.core.settings")
local config = require("craftmind.config")
settingsx.defineAll()
settingsx.set(config.settings.workspace, "/workspace")
settingsx.set(config.settings.safety, "safe")
settingsx.set(config.settings.profile, "admin")
local luaAgent = require("craftmind.ai.lua_agent")
assert(not luaAgent.canRunRawLua(), "legacy profile admin must not unlock raw Lua")
settingsx.set(config.settings.safety, "power")
assert(luaAgent.canRunRawLua(), "safety=power should unlock raw Lua")
settingsx.set(config.settings.safety, "safe")
settingsx.set(config.settings.authToken, "")
assert(settingsx.remoteAuthStatus() == "locked", "blank auth token should lock remote control")
settingsx.set(config.settings.authToken, "smoke-token")
assert(settingsx.remoteAuthStatus() == "auth-token", "nonblank auth token should enable token auth")
settingsx.set(config.settings.authToken, "")

local tools = require("craftmind.ai.workspace_tools")
assert(type(tools.root()) == "string", "workspace root missing")
assert(tools.root() ~= "", "workspace root empty")

local identity = require("craftmind.identity")
local id = identity.ensureAgent("test-smoke")
assert(id == "test-smoke", "identity.ensureAgent returned wrong id")
assert(fs.exists(fs.combine(tools.root(), ".craftmind/agents/test-smoke/identity.md")), "identity file missing")
assert(fs.exists(fs.combine(tools.root(), ".craftmind/docs/computercraft-quick-reference.md")), "quick reference doc missing")
assert(fs.exists(fs.combine(tools.root(), ".craftmind/docs/bundled/tools.md")), "bundled docs mirror missing")
local docs = require("craftmind.docs.index")
local docCtx = docs.context("workspace tools")
assert(docCtx:find("CraftMind docs manifest", 1, true), "docs context should be manifest")
assert(docCtx:find(".craftmind/docs/bundled/tools.md", 1, true), "docs manifest missing bundled tool doc")

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
local turtleOps = tools.extract([[<craftmind-turtle action="discover" /><craftmind-turtle action="run_lua" id="1">print("hi")</craftmind-turtle>]])
assert(#turtleOps == 2 and turtleOps[1].type == "turtle" and turtleOps[1].action == "discover", "turtle tool extract failed")
assert(turtleOps[2].code:find("print", 1, true), "turtle run_lua body missing")
local ok, result = tools.run(ops[1])
assert(ok, "tool list failed: " .. tostring(result))

local ordered = tools.extract([[<craftmind-file path="order.txt" mode="write">one</craftmind-file><craftmind-read path="order.txt" />]])
assert(#ordered == 2 and ordered[1].type == "file" and ordered[2].type == "read", "tool order not preserved")
ok, result = tools.run(ordered[1])
assert(ok, "tool write failed: " .. tostring(result))
ok, result = tools.run(ordered[2])
assert(ok and result == "one", "tool read after write failed")
local repl = tools.extract([[<craftmind-replace path="order.txt"><old>one</old><new>two</new></craftmind-replace>]])
assert(#repl == 1 and repl[1].type == "replace", "replace extract failed")
ok, result = tools.run(repl[1])
assert(ok, "replace failed: " .. tostring(result))
ok, result = tools.run({ type = "read", path = "order.txt" })
assert(ok and result == "two", "replace did not update file")
ok, result = tools.run({ type = "read", path = "../escape.txt" })
assert(not ok and tostring(result):find("parent paths not allowed", 1, true), "parent path was not blocked")

local pipeline = require("craftmind.ai.runtime_pipeline")
local modelCalls = 0
local pipeOk, pipeResult = pipeline.run("pipeline smoke", {
  agentId = "test-smoke",
  sessionId = "pipeline-smoke",
  maxSteps = 2,
  modelFn = function(modelCtx)
    modelCalls = modelCalls + 1
    assert(modelCtx.route.channel == "terminal", "pipeline channel mismatch")
    assert(modelCtx.route.agentId == "test-smoke", "pipeline route mismatch")
    assert(type(modelCtx.messages) == "table" and #modelCtx.messages > 0, "pipeline context missing messages")
    if modelCalls == 1 then return "Checking workspace.\n<craftmind-list path=\".\" />" end
    assert(modelCtx.prior[#modelCtx.prior].content:find("Tool observations:", 1, true), "pipeline did not feed tool observations")
    return "Pipeline complete."
  end,
})
assert(pipeOk, "pipeline failed: " .. tostring(pipeResult))
assert(modelCalls == 2, "pipeline did not continue after tool")
assert(#pipeResult.steps == 2, "pipeline step count mismatch")
assert(#pipeResult.steps[1].ops == 1 and pipeResult.steps[1].ops[1].type == "list", "pipeline tools stage failed")
assert(not pipeResult.hitLimit, "pipeline should stop after no-tool reply")
local pipeRecent = session.recent("pipeline-smoke", 4)
assert(#pipeRecent == 4, "pipeline persist stage mismatch")
assert(pipeRecent[1].role == "user" and pipeRecent[1].content == "pipeline smoke", "pipeline user persist mismatch")
assert(pipeRecent[3].content:find("Tool observations:", 1, true), "pipeline observation persist mismatch")

local onboarding = require("craftmind.onboarding")
local onboardOk, onboardState = onboarding.run({
  "--non-interactive",
  "--accept-risk",
  "--provider=groq",
  "--workspace=/workspace",
  "--agent-id=onboard-smoke",
  "--agent-name=Onboard Smoke",
  "--seed-skills=true",
})
assert(onboardOk, "onboarding failed: " .. tostring(onboardState))
assert(settingsx.onboardingCompleted(), "onboarding completion flag missing")
assert(fs.exists(fs.combine(tools.root(), ".craftmind/agents/onboard-smoke/identity.md")), "onboarded agent missing")
assert(fs.exists(fs.combine(tools.root(), ".craftmind/skills/turtle-safety/SKILL.md")), "seeded skill missing")

print("CraftMind ComputerCraft smoke OK")
