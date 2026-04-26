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
