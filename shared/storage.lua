-- WiRe Rewired storage helpers
-- Small, reusable helpers for configuration files outside the legacy programs.

local storage = {}

local function ensureParent(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

function storage.readText(path, fallback)
  if not fs.exists(path) then return fallback end
  local f = fs.open(path, "r")
  if not f then return fallback end
  local raw = f.readAll()
  f.close()
  return raw
end

function storage.writeText(path, value)
  ensureParent(path)
  local f = fs.open(path, "w")
  if not f then return false, "cannot write " .. tostring(path) end
  f.write(tostring(value or ""))
  f.close()
  return true
end

function storage.saveTable(path, data)
  local ok, serialised = pcall(textutils.serialize, data)
  if not ok then return false, "cannot serialise " .. tostring(path) end
  return storage.writeText(path, serialised)
end

function storage.loadTable(path, fallback)
  local raw = storage.readText(path, nil)
  if raw == nil then return fallback end
  local ok, result = pcall(textutils.unserialize, raw)
  if ok and result ~= nil then return result end
  return fallback
end

function storage.trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

return storage
