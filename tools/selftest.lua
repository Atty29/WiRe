-- WiRe Rewired development self-test
-- Checks the installed package structure without operating redstone devices.

local required = {
  "wire/runtime/launcher.lua",
  "wire/shared/version.lua",
  "wire/shared/team.lua",
  "wire/shared/components.lua",
  "wire/shared/config.lua",
  "wire/shared/protocol.lua",
  "wire/shared/storage.lua",
  "wire/tools/update.lua",
  "wire/tools/team.lua",
  "wire/version.txt",
}

local function result(ok, message)
  term.setTextColor(ok and colors.green or colors.red)
  print((ok and "[PASS] " or "[FAIL] ") .. message)
  term.setTextColor(colors.white)
  return ok
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("WiRe Rewired Development Self-Test")
print("")

local allOk = true
for i = 1, #required do
  local ok = fs.exists(required[i])
  allOk = result(ok, required[i]) and allOk
end

local okStorage, storage = pcall(dofile, "wire/shared/storage.lua")
allOk = result(okStorage and type(storage) == "table" and type(storage.readText) == "function", "storage module loads") and allOk

local okComponents, components = pcall(dofile, "wire/shared/components.lua")
allOk = result(okComponents and type(components) == "table" and type(components.isValid) == "function", "component registry loads") and allOk

local okConfig, config = pcall(dofile, "wire/shared/config.lua")
allOk = result(okConfig and type(config) == "table" and type(config.mergeDefaults) == "function", "configuration service loads") and allOk

if okConfig and type(config) == "table" then
  local defaults = config.clientDefaults()
  local sample = { name = "Test Device", color = "Light Blue", getFix = false, deviceType = "Bridge" }

  -- Migrations must run against the original legacy table before defaults are
  -- merged. Otherwise a modern default such as newColors=true can hide the
  -- fact that an old colour name still needs converting.
  local migrated, changed = config.migrateClient(config.clone(sample))
  migrated = config.mergeDefaults(migrated, defaults)

  allOk = result(migrated.name == "Test Device" and migrated.side == "top", "config defaults preserve existing values") and allOk
  allOk = result(changed == true and migrated.color == "Sky" and migrated.getGPSFix == false and migrated.deviceType == "Energy", "legacy client migration is compatible") and allOk
end

local component
if okStorage and okComponents then
  component = storage.trim(storage.readText("wire/component.cfg", ""))
else
  component = nil
end
allOk = result(component ~= nil and okComponents and components.isValid(component), "component.cfg: " .. tostring(component or "missing")) and allOk
if component and okComponents and components.isValid(component) then
  local path = components.path(component)
  allOk = result(path ~= nil and fs.exists(path), "component program: " .. tostring(path)) and allOk
end

local okVersion, version = pcall(dofile, "wire/shared/version.lua")
allOk = result(okVersion and type(version) == "table" and version.version ~= nil, "version module loads") and allOk
if okVersion and type(version) == "table" then print("       version " .. tostring(version.version)) end

local okTeam, team = pcall(dofile, "wire/shared/team.lua")
allOk = result(okTeam and type(team) == "table" and type(team.protocol) == "function", "team module loads") and allOk
if okTeam and type(team) == "table" then
  local cfg = team.load()
  if cfg then
    print("       " .. team.describe(cfg))

    if cfg.enabled then
      local configuredColour
      if okConfig and component == "server" and fs.exists("/data/WiReServerCfg") then
        local serverCfg = config.load("/data/WiReServerCfg", config.serverDefaults(), {
          requireExisting = true,
          migrate = config.migrateServer,
          saveMigrated = false,
        })
        if type(serverCfg) == "table" then configuredColour = serverCfg.color end
      elseif okConfig and component == "client" and fs.exists("/data/WiReClientCfg") then
        local clientCfg = config.load("/data/WiReClientCfg", config.clientDefaults(), {
          requireExisting = true,
          migrate = config.migrateClient,
          saveMigrated = false,
        })
        if type(clientCfg) == "table" then configuredColour = clientCfg.color end
      end

      if configuredColour and configuredColour ~= "" then
        local protocolName = "WiRe" .. tostring(configuredColour)
        print("       " .. tostring(configuredColour) .. " => " .. team.protocol(cfg, protocolName))
      else
        print("       Example: Purple => " .. team.protocol(cfg, "WiRePurple"))
      end
    end
  else
    term.setTextColor(colors.yellow)
    print("[INFO] Team is not configured yet; launcher will ask on first start.")
    term.setTextColor(colors.white)
  end
end

print("")
if allOk then
  term.setTextColor(colors.green)
  print("Installation structure looks good.")
  print("Next: run the launcher and perform the in-game tests.")
else
  term.setTextColor(colors.red)
  print("One or more installation checks failed.")
  print("Re-run the development installer before testing devices.")
end
term.setTextColor(colors.white)
