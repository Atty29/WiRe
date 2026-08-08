-- WiRe Rewired development updater
-- Downloads a fresh copy of the development installer and runs it for the
-- currently installed component. A cache-busting URL is used so GitHub/CDN
-- caching cannot leave WiRe stuck reinstalling an older build.

local INSTALLER = "https://raw.githubusercontent.com/Atty29/WiRe/development/installer/install-dev.lua"
local COMPONENT_FILE = "wire/component.cfg"
local TEMP_INSTALLER = "wire/.update-installer.lua"

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function cacheStamp()
  if os.epoch then
    local ok, value = pcall(os.epoch, "utc")
    if ok and value then return tostring(value) end
  end
  return tostring(math.floor((os.time() or 0) * 100000) + math.random(1, 99999))
end

local function freshUrl(url)
  return url .. "?wire_update=" .. cacheStamp()
end

local function downloadFreshInstaller()
  local response, err = http.get(freshUrl(INSTALLER), { ["Cache-Control"] = "no-cache" })
  if not response then return false, err end
  local data = response.readAll()
  response.close()

  local f = fs.open(TEMP_INSTALLER, "w")
  if not f then return false, "cannot write " .. TEMP_INSTALLER end
  f.write(data)
  f.close()
  return true
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

if not http then error("HTTP API is not enabled in CC:Tweaked.", 0) end

print("Downloading fresh installer...")
local gotInstaller, installerErr = downloadFreshInstaller()
if not gotInstaller then
  term.setTextColor(colors.red)
  error("Could not download development installer: " .. tostring(installerErr), 0)
end
term.setTextColor(colors.green)
print("Fresh installer downloaded.")
term.setTextColor(colors.white)
print("")

local ok
if component then
  print("Updating installed component: " .. component)
  print("Team and WiRe configuration under /data are preserved.")
  print("")
  ok = shell.run(TEMP_INSTALLER, component, "--unattended")
else
  print("No installed component was recorded.")
  print("Opening the development installer...")
  print("")
  ok = shell.run(TEMP_INSTALLER)
end

if fs.exists(TEMP_INSTALLER) then fs.delete(TEMP_INSTALLER) end

if ok == false then
  term.setTextColor(colors.red)
  error("Development update did not complete successfully.", 0)
end
