local M = {}

function M.ensure()
  if not http then error("ComputerCraft HTTP API is disabled") end
end

function M.jsonPost(url, payload, headers)
  M.ensure()
  headers = headers or {}
  headers["Content-Type"] = headers["Content-Type"] or "application/json"
  local body = textutils.serializeJSON(payload)
  local res, err = http.post(url, body, headers)
  if not res then return nil, err or "http.post failed" end
  local text = res.readAll()
  local code = res.getResponseCode and res.getResponseCode() or nil
  res.close()
  local ok, decoded = pcall(textutils.unserializeJSON, text)
  if not ok then return nil, "JSON parse failed: " .. tostring(decoded) .. " body=" .. tostring(text) end
  if code and (code < 200 or code >= 300) then return nil, "HTTP " .. tostring(code) .. ": " .. tostring(text) end
  return decoded, nil
end

return M
