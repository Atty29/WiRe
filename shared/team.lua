-- WiRe Rewired team/profile helper
--
-- Teams isolate otherwise identical WiRe colour networks from one another.
-- The existing WiRe programs still see their familiar protocols (for example
-- WiRePurple). runtime/launcher.lua maps those protocols into a team namespace.
-- This allows each team to use the normal 16 ComputerCraft colours independently.

local team = {}

team.configPath = "/data/WiRe/team.cfg"
team.defaultName = "DEFAULT"

local function loadStorage()
  local paths = {
    "wire/shared/storage.lua",
    "shared/storage.lua",
  }
  for i = 1, #paths do
    if fs.exists(paths[i]) then
      local ok, module = pcall(dofile, paths[i])
      if ok and type(module) == "table" then return module end
    end
  end
  return nil
end

local storage = loadStorage()

function team.slugify(value)
  local slug = tostring(value or ""):upper()
  slug = slug:gsub("[^A-Z0-9_-]", "-")
  slug = slug:gsub("%-+", "-")
  slug = slug:gsub("^%-", ""):gsub("%-$", "")
  if slug == "" then slug = team.defaultName end
  return slug:sub(1, 24)
end

function team.defaults()
  return {
    enabled = true,
    name = team.defaultName,
    slug = team.defaultName,
  }
end

function team.normalise(cfg)
  cfg = type(cfg) == "table" and cfg or team.defaults()
  if cfg.enabled == nil then cfg.enabled = true end
  cfg.name = tostring(cfg.name or team.defaultName):sub(1, 32)
  cfg.slug = team.slugify(cfg.slug or cfg.name)
  return cfg
end

function team.load()
  if storage and type(storage.loadTable) == "function" then
    local cfg = storage.loadTable(team.configPath, nil)
    return cfg and team.normalise(cfg) or nil
  end

  if not fs.exists(team.configPath) then return nil end
  local f = fs.open(team.configPath, "r")
  if not f then return nil end
  local raw = f.readAll()
  f.close()
  local ok, cfg = pcall(textutils.unserialize, raw)
  if not ok or type(cfg) ~= "table" then return nil end
  return team.normalise(cfg)
end

function team.save(cfg)
  cfg = team.normalise(cfg)
  if storage and type(storage.saveTable) == "function" then
    return storage.saveTable(team.configPath, cfg)
  end

  if not fs.exists("/data") then fs.makeDir("/data") end
  if not fs.exists("/data/WiRe") then fs.makeDir("/data/WiRe") end
  local f = fs.open(team.configPath, "w")
  if not f then return false, "cannot write " .. team.configPath end
  f.write(textutils.serialize(cfg))
  f.close()
  return true
end

function team.protocol(cfg, protocol)
  cfg = team.normalise(cfg)
  if not cfg.enabled then return protocol end
  if type(protocol) ~= "string" or protocol:sub(1, 4) ~= "WiRe" then return protocol end
  return "WiReRewired:" .. cfg.slug .. ":" .. protocol
end

function team.describe(cfg)
  cfg = team.normalise(cfg)
  if not cfg.enabled then return "Legacy network (team isolation disabled)" end
  return cfg.name .. " [" .. cfg.slug .. "]"
end

return team
