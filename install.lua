-- CraftMind public GitHub installer for ComputerCraft
-- Project idea: OpenClaw-style AI workspace agent for ComputerCraft.

local OWNER = "TJKDev1"
local REPO = "CraftMind"
local BRANCH = "main"
local BASE_DIR = "craftmind"
local REMOTE_VERSION = "0.3.5"
local CACHE_BUST = tostring((os.epoch and os.epoch("utc")) or os.time())

local files = {
  "README.md",
  "manifest.lua",
  "config.lua",
  "boot.lua",
  "core/http.lua",
  "core/logger.lua",
  "core/settings.lua",
  "providers/init.lua",
  "providers/openai_compat.lua",
  "providers/groq.lua",
  "providers/gemini.lua",
  "providers/nvidia.lua",
  "ai/chat.lua",
  "ai/lua_agent.lua",
  "ai/tool_runner.lua",
  "ai/context.lua",
  "ai/session.lua",
  "ai/runtime_pipeline.lua",
  "ai/workspace_agent.lua",
  "ai/workspace_tools.lua",
  "ai/orchestrator.lua",
  "identity/init.lua",
  "onboarding/init.lua",
  "docs/index.lua",
  "docs/craftmind.md",
  "docs/agents.md",
  "docs/tools.md",
  "docs/openclaw-adaptation.md",
  "tools/file.lua",
  "ui/menu.lua",
  "ui/render.lua",
  "apps/setup.lua",
  "apps/chat.lua",
  "apps/agent.lua",
  "apps/agents.lua",
  "apps/remote.lua",
  "apps/turtle.lua",
  "turtle/server.lua",
  "client/remote.lua",
}

local stats = { downloaded = 0, updated = 0, unchanged = 0 }

local function ensureHttp()
  if not http then error("HTTP API disabled. Enable http in ComputerCraft server config.") end
end

local function ensureDir(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

local function readFile(path)
  if not fs.exists(path) then return nil end
  local f = fs.open(path, "r")
  local body = f.readAll()
  f.close()
  return body
end

local function currentVersion()
  local manifestPath = fs.combine(BASE_DIR, "manifest.lua")
  if not fs.exists(BASE_DIR) then return nil, "missing" end
  if not fs.exists(manifestPath) then return nil, "no_manifest" end

  local ok, manifest = pcall(dofile, manifestPath)
  if ok and type(manifest) == "table" and manifest.version then
    return tostring(manifest.version), "ok"
  end
  return nil, "bad_manifest"
end

local function rawUrl(path)
  return "https://raw.githubusercontent.com/" .. OWNER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. BASE_DIR .. "/" .. path .. "?bust=" .. CACHE_BUST
end

local function download(path)
  local url = rawUrl(path)
  local target = fs.combine(BASE_DIR, path)
  print("Downloading " .. target)
  local res, err = http.get(url, { ["User-Agent"] = "ComputerCraft" })
  if not res then return false, tostring(err) end
  local code = res.getResponseCode and res.getResponseCode() or 200
  local body = res.readAll()
  res.close()
  if code < 200 or code >= 300 then return false, "HTTP " .. tostring(code) .. " from " .. url end

  local old = readFile(target)
  ensureDir(target)
  local f = fs.open(target, "w")
  f.write(body)
  f.close()

  stats.downloaded = stats.downloaded + 1
  if old == body then stats.unchanged = stats.unchanged + 1 else stats.updated = stats.updated + 1 end
  return true
end

local function install()
  ensureHttp()

  local oldVersion, state = currentVersion()
  local action
  if state == "missing" then
    action = "Installing"
  elseif state == "ok" and oldVersion == REMOTE_VERSION then
    action = "Reinstalling/updating"
  elseif state == "ok" then
    action = "Updating"
  else
    action = "Repairing"
  end

  print("CraftMind installer")
  print("Source: " .. OWNER .. "/" .. REPO .. "@" .. BRANCH)
  print("Mode: " .. action)
  print("Current: " .. tostring(oldVersion or state))
  print("Target: " .. REMOTE_VERSION)
  print("")

  for _, path in ipairs(files) do
    local ok, err = download(path)
    if not ok then error("Failed to download " .. path .. ": " .. tostring(err)) end
  end

  print("")
  print(action .. " complete.")
  print("Files checked: " .. stats.downloaded)
  print("Changed: " .. stats.updated .. " | Unchanged: " .. stats.unchanged)
  print("Run: /craftmind/boot.lua")
end

install()
