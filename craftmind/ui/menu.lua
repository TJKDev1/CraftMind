local M = {}

function M.choose(title, items)
  while true do
    term.clear()
    term.setCursorPos(1, 1)
    print(title)
    print(string.rep("=", #title))
    for i, item in ipairs(items) do print(i .. ") " .. item.label) end
    print("q) Quit")
    write("> ")
    local ans = read()
    if ans == "q" or ans == "Q" then return nil end
    local n = tonumber(ans)
    if n and items[n] then return items[n], n end
  end
end

function M.prompt(label, default)
  write(label)
  if default and default ~= "" then write(" [" .. tostring(default) .. "]") end
  write(": ")
  local v = read()
  if v == "" then return default end
  return v
end

function M.pause()
  print("Press enter...")
  read()
end

return M
