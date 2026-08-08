-- WiRe Rewired shared configuration service
--
-- Provides one safe place for loading, saving, merging defaults and applying
-- migrations to WiRe configuration tables. Existing legacy Server/Client
-- programs can adopt this module incrementally without changing their on-disk
-- data format.

local config = {}

local function tryLoadStorage()
  local candidates = {
    "wire/shared/storage.lua",
    "shared/storage.lua",
  }
  for i = 1, #candidates do
    if fs.exists(candidates[i]) then
      local ok, module = pcall(dofile, candidates[i])
      if ok and type(module) == "table" then return module end
    end
  end
  return nil
end

local storage = tryLoadStorage()

local function clone(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for k, v in pairs(value) do out[k] = clone(v) end
  return out
end

local function mergeMissing(target, defaults)
  target = type(target) == "table" and target or {}
  defaults = type(defaults) == "table" and defaults or {}
  for k, v in pairs(defaults) do
    if target[k] == nil then
      target[k] = clone(v)
    elseif type(target[k]) == "table" and type(v) == "table" then
      mergeMissing(target[k], v)
    end
  end
  return target
end

local function ensureParent(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

local function fallbackLoad(path)
  if not fs.exists(path) then return nil, "missing" end
  local f = fs.open(path, "r")
  if not f then return nil, "cannot open " .. path end
  local raw = f.readAll()
  f.close()
  local ok, value = pcall(textutils.unserialize, raw)
  if not ok or type(value) ~= "table" then return nil, "invalid configuration" end
  return value
end

local function fallbackSave(path, value)
  ensureParent(path)
  local f = fs.open(path, "w")
  if not f then return false, "cannot write " .. path end
  f.write(textutils.serialize(value))
  f.close()
  return true
end

function config.clone(value)
  return clone(value)
end

function config.mergeDefaults(value, defaults)
  return mergeMissing(value, defaults)
end

function config.load(path, defaults, options)
  options = type(options) == "table" and options or {}

  local value, err
  if storage and type(storage.loadTable) == "function" then
    value = storage.loadTable(path, nil)
    if value == nil then err = fs.exists(path) and "invalid configuration" or "missing" end
  else
    value, err = fallbackLoad(path)
  end

  if value == nil then
    if options.requireExisting then return nil, err end
    value = clone(defaults or {})
  end

  if type(value) ~= "table" then return nil, "configuration is not a table" end
  value = mergeMissing(value, defaults or {})

  if type(options.migrate) == "function" then
    local ok, migrated, changed = pcall(options.migrate, value)
    if not ok then return nil, "migration failed: " .. tostring(migrated) end
    if type(migrated) == "table" then value = migrated end
    if changed and options.saveMigrated ~= false then
      local saveOk, saveErr = config.save(path, value)
      if not saveOk then return nil, saveErr end
    end
  end

  return value
end

function config.save(path, value)
  if type(value) ~= "table" then return false, "configuration must be a table" end
  if storage and type(storage.saveTable) == "function" then
    return storage.saveTable(path, value)
  end
  return fallbackSave(path, value)
end

function config.serverDefaults()
  return {
    name = "WiReServer",
    note = "short note",
    color = "Silver",
    getGPSFix = true,
    newColors = true,
  }
end

function config.clientDefaults()
  return {
    name = "WiReClient",
    note = "short note",
    color = "Silver",
    side = "top",
    deviceType = "Door",
    autoClose = true,
    autoDelay = 3,
    onState = false,
    offState = true,
    defaultStart = false,
    lastState = false,
    lockState = false,
    getGPSFix = true,
    newColors = true,
  }
end

function config.migrateCommonColours(value)
  local changed = false
  if value.getFix ~= nil then
    value.getGPSFix = value.getFix
    value.getFix = nil
    changed = true
  end
  if not value.newColors then
    if value.color == "lgray" or value.color == "Light Gray" then
      value.color = "Silver"
    elseif value.color == "lblue" or value.color == "Light Blue" then
      value.color = "Sky"
    end
    value.newColors = true
    changed = true
  end
  return value, changed
end

function config.migrateServer(value)
  return config.migrateCommonColours(value)
end

function config.migrateClient(value)
  local changed = false
  local migrated, commonChanged = config.migrateCommonColours(value)
  value = migrated
  changed = changed or commonChanged
  if value.deviceType == "Bridge" then
    value.deviceType = "Energy"
    changed = true
  end
  return value, changed
end

return config
