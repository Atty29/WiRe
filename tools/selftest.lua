-- WiRe Rewired development self-test
-- Checks the installed package structure without operating redstone devices.

local required = {
  "wire/runtime/launcher.lua",
  "wire/shared/version.lua",
  "wire/shared/team.lua",
  "wire/shared/components.lua",
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
      print("       Purple => " .. team.protocol(cfg, "WiRePurple"))
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
