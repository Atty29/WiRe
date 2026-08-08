-- WiRe Rewired update preference tool

local STORAGE = "wire/shared/storage.lua"
local PREFS = "/data/WiRe/update.cfg"

if not fs.exists(STORAGE) then error("Missing " .. STORAGE, 0) end
local storage = dofile(STORAGE)

local prefs = storage.loadTable(PREFS, {})
if type(prefs) ~= "table" then prefs = {} end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("WiRe Rewired Update Settings")
print("")
print("Current: " .. ((prefs.mode == "never") and "Automatic checks disabled" or "Ask when an update is available"))
print("")
print("1) Ask when updates are available")
print("2) Never check automatically")
print("3) Exit")
print("")
write("Select: ")
local choice = storage.trim(read())

if choice == "1" then
  prefs.mode = "prompt"
  local ok, err = storage.saveTable(PREFS, prefs)
  if ok == false then error(err, 0) end
  print("Automatic update checks enabled.")
elseif choice == "2" then
  prefs.mode = "never"
  local ok, err = storage.saveTable(PREFS, prefs)
  if ok == false then error(err, 0) end
  print("Automatic update checks disabled.")
else
  print("No changes made.")
end
