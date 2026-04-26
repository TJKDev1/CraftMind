-- CraftMind public GitHub installer for ComputerCraft

local OWNER = "TJKDev1"
local REPO = "CraftMind"
local BRANCH = "main"
local BASE_DIR = "craftmind"

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
  "docs/index.lua",
  "tools/file.lua",
  "ui/menu.lua",
  "apps/setup.lua",
  "apps/chat.lua",
  "turtle/server.lua",
  "client/remote.lua",
}

local function ensureHttp()
  if not http then error("HTTP API disabled. Enable http in ComputerCraft server config.") end
end

local function ensureDir(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

local function rawUrl(path)
  return "https://raw.githubusercontent.com/" .. OWNER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. BASE_DIR .. "/" .. path
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
  ensureDir(target)
  local f = fs.open(target, "w")
  f.write(body)
  f.close()
  return true
end

local function install()
  ensureHttp()
  print("CraftMind installer")
  print("Source: " .. OWNER .. "/" .. REPO .. "@" .. BRANCH)
  print("")
  for _, path in ipairs(files) do
    local ok, err = download(path)
    if not ok then error("Failed to download " .. path .. ": " .. tostring(err)) end
  end
  print("")
  print("Install complete.")
  print("Run: /craftmind/boot.lua")
end

install()
