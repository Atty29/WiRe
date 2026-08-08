-- WiRe Rewired development updater
-- Re-runs the manifest-driven installer for the currently installed component.

local INSTALLER = "https://raw.githubusercontent.com/Atty29/WiRe/development/installer/install-dev.lua"
local COMPONENT_FILE = "wire/component.cfg"

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local component
if fs.exists(COMPONENT_FILE) then
  local f = fs.open(COMPONENT_FILE, "r")
  if f then
    component = trim(f.readAll())
    f.close()
  end
end

local valid = { server = true, client = true, trigger = true, sensor = true, tablet = true }
if component and not valid[component] then component = nil end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("WiRe Rewired Development Updater")
print("")
if component then
  print("Updating installed component: " .. component)
  print("Team and WiRe configuration under /data are preserved.")
  print("")
  shell.run("wget", "run", INSTALLER, component, "--unattended")
else
  print("No installed component was recorded.")
  print("Opening the development installer...")
  print("")
  shell.run("wget", "run", INSTALLER)
end
