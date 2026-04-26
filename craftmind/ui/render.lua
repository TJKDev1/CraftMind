local M = {}

local function hasColor()
  return term.isColor and term.isColor()
end

local function setText(color)
  if hasColor() and term.setTextColor then term.setTextColor(color) end
end

local function setBg(color)
  if hasColor() and term.setBackgroundColor then term.setBackgroundColor(color) end
end

local function reset()
  setText(colors.white)
  setBg(colors.black)
end

local function line(char, width)
  print(string.rep(char, width or 32))
end

local function wrap(text, width)
  width = width or select(1, term.getSize()) or 50
  local out = {}
  for raw in string.gmatch(text .. "\n", "([^\n]*)\n") do
    local lineText = raw
    while #lineText > width do
      local cut = width
      for i = width, 1, -1 do
        if string.sub(lineText, i, i) == " " then cut = i; break end
      end
      table.insert(out, string.sub(lineText, 1, cut))
      lineText = string.sub(lineText, cut + 1)
    end
    table.insert(out, lineText)
  end
  return out
end

function M.thinking(text)
  local w = select(1, term.getSize()) or 50
  setText(colors.gray)
  line("-", math.min(w, 48))
  print("thinking")
  line("-", math.min(w, 48))
  for _, l in ipairs(wrap(text, w - 2)) do
    print(" " .. l)
  end
  line("-", math.min(w, 48))
  reset()
end

function M.assistant(text)
  setText(colors.lime)
  write("\nCraftMind> ")
  reset()
  print(text)
end

function M.error(text)
  setText(colors.red)
  print("Error: " .. tostring(text))
  reset()
end

function M.renderAssistant(raw)
  raw = raw or ""
  local pos = 1
  local shown = false

  while true do
    local s, e, inner = string.find(raw, "<thinking>(.-)</thinking>", pos)
    if not s then break end

    local before = string.sub(raw, pos, s - 1)
    if before ~= "" and before:match("%S") then
      M.assistant((before:gsub("^%s+", ""):gsub("%s+$", "")))
      shown = true
    end

    M.thinking((inner:gsub("^%s+", ""):gsub("%s+$", "")))
    shown = true
    pos = e + 1
  end

  local rest = string.sub(raw, pos)
  rest = rest:gsub("^%s+", ""):gsub("%s+$", "")
  if rest ~= "" then
    M.assistant(rest)
    shown = true
  end

  if not shown then M.assistant(raw) end
end

return M
