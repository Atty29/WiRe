-- WiRe Rewired component configuration registry
--
-- Keeps component-specific config paths/defaults/migrations out of the launcher.
-- This is an intermediate step toward letting Server/Client consume the shared
-- configuration service directly.

local registry = {}

local function loadConfigService()
  local candidates = {
    "wire/shared/config.lua",
    "shared/config.lua",
  }
  for i = 1, #candidates do
    if fs.exists(candidates[i]) then
      local ok, module = pcall(dofile, candidates[i])
      if ok and type(module) == "table" then return module end
    end
  end
  error("WiRe Rewired component_config: config service not found", 0)
end

local config = loadConfigService()

local definitions = {
  server = {
    path = "/data/WiReServerCfg",
    defaults = config.serverDefaults,
    migrate = config.migrateServer,
  },
  client = {
    path = "/data/WiReClientCfg",
    defaults = config.clientDefaults,
    migrate = config.migrateClient,
  },
}

function registry.definition(component)
  return definitions[component]
end

function registry.supports(component)
  return definitions[component] ~= nil
end

function registry.preflight(component)
  local def = definitions[component]
  if not def then return true, nil end
  if not fs.exists(def.path) then return true, nil end

  local cfg, err = config.load(def.path, def.defaults(), {
    requireExisting = true,
    migrate = def.migrate,
    saveMigrated = true,
  })
  if not cfg then return false, err end

  local ok, saveErr = config.save(def.path, cfg)
  if ok == false then return false, saveErr end
  return true, cfg
end

return registry
