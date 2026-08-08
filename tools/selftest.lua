-- WiRe Rewired development self-test
-- Checks the installed package structure without operating redstone devices.

local required = {
  "wire/runtime/launcher.lua",
  "wire/shared/version.lua",
  "wire/shared/team.lua",
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

local component
if fs.exists("wire/component.cfg") then
  local f = fs.open("wire/component.cfg", "r")
  if f then component = (f.readAll() or ""):gsub("%s+", ""); f.close() end
end
local valid = { server = true, client = true, trigger = true, sensor = true, tablet = true }
allOk = result(component ~= nil and valid[component] == true, "component.cfg: " .. tostring(component or "missing")) and allOk
if component and valid[component] then
  allOk = result(fs.exists("wire/" .. component .. ".lua"), "component program: wire/" .. component .. ".lua") and allOk
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
