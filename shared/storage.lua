-- WiRe storage helpers

local storage = {}

function storage.saveTable(path, data)
  local f = fs.open(path, "w")
  f.write(textutils.serialize(data))
  f.close()
end

function storage.loadTable(path, fallback)
  if not fs.exists(path) then return fallback end
  local f = fs.open(path, "r")
  local raw = f.readAll()
  f.close()
  local ok, result = pcall(textutils.unserialize, raw)
  if ok and result ~= nil then return result end
  return fallback
end

return storage
