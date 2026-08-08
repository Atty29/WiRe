--==============================================================--
--               WiRe Rewired Development Installer           --
--==============================================================--

local BRANCH = "development"
local BASE_URL = "https://raw.githubusercontent.com/Atty29/WiRe/" .. BRANCH .. "/"
local MANIFEST_URL = BASE_URL .. "manifest.lua"
local args = { ... }

local function clear()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
end

local function line(text, colour)
  if colour then term.setTextColor(colour) end
  print(text)
  term.setTextColor(colors.white)
end

local function askYesNo(question, defaultYes)
  while true do
    write(question .. (defaultYes and " [Y/n]: " or " [y/N]: "))
    local answer = string.lower(read() or "")
    if answer == "" then return defaultYes end
    if answer == "y" or answer == "yes" then return true end
    if answer == "n" or answer == "no" then return false end
  end
end

local function httpRead(url)
  local response, err = http.get(url)
  if not response then return nil, err end
  local data = response.readAll()
  response.close()
  return data
end

local function loadManifest()
  line("Loading development manifest...", colors.lightBlue)
  local raw, err = httpRead(MANIFEST_URL)
  if not raw then error("Could not download manifest: " .. tostring(err), 0) end

  local chunk, loadErr
  if loadstring then
    chunk, loadErr = loadstring(raw, "@manifest.lua")
    if chunk and setfenv then setfenv(chunk, {}) end
  else
    chunk, loadErr = load(raw, "@manifest.lua", "t", {})
  end
  if not chunk then error("Could not parse manifest: " .. tostring(loadErr), 0) end

  local ok, manifest = pcall(chunk)
  if not ok or type(manifest) ~= "table" or type(manifest.packages) ~= "table" then
    error("Development manifest is invalid: " .. tostring(manifest), 0)
  end
  return manifest
end

local function ensureDir(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

local function downloadFile(manifest, entry)
  local url = manifest.baseUrl .. entry.src
  local data, err = httpRead(url)
  if not data then return false, "download failed for " .. entry.src .. ": " .. tostring(err) end
  ensureDir(entry.dest)
  local f = fs.open(entry.dest, "w")
  if not f then return false, "cannot write " .. entry.dest end
  f.write(data)
  f.close()
  return true
end

local function installFiles(manifest, package)
  local files = {}
  for i = 1, #(manifest.common or {}) do files[#files + 1] = manifest.common[i] end
  for i = 1, #(package.files or {}) do files[#files + 1] = package.files[i] end

  for i = 1, #files do
    local entry = files[i]
    write("[" .. tostring(i) .. "/" .. tostring(#files) .. "] " .. entry.dest .. " ... ")
    local ok, err = downloadFile(manifest, entry)
    if not ok then
      line("FAILED", colors.red)
      error(err, 0)
    end
    line("OK", colors.green)
  end
end

local function saveComponent(component)
  if not component then return end
  ensureDir("wire/component.cfg")
  local f = fs.open("wire/component.cfg", "w")
  if not f then error("Could not write wire/component.cfg", 0) end
  f.write(component)
  f.close()
end

local function isWiReStartup()
  if not fs.exists("startup.lua") then return false end
  local f = fs.open("startup.lua", "r")
  if not f then return false end
  local raw = f.readAll()
  f.close()
  return string.find(raw, "WiRe Rewired development auto%-start") ~= nil
end

local function installStartup(component, unattended)
  if not component then return false end
  local replace = false

  if unattended then
    -- An updater must never hijack a user's custom startup.lua. It only refreshes
    -- a startup file that was previously created by this development installer.
    replace = isWiReStartup()
  elseif fs.exists("startup.lua") then
    line("startup.lua already exists.", colors.orange)
    replace = askYesNo("Replace it with the WiRe Rewired launcher?", false)
  else
    replace = askYesNo("Start WiRe Rewired automatically on boot?", true)
  end

  if not replace then return false end

  local f = fs.open("startup.lua", "w")
  if not f then error("Could not write startup.lua", 0) end
  f.writeLine("-- WiRe Rewired development auto-start")
  f.writeLine("shell.run(\"wire/runtime/launcher.lua\", \"" .. component .. "\")")
  f.close()
  return true
end

local function choosePackage(manifest)
  local order = { "server", "client", "trigger", "sensor", "tablet", "full" }
  clear()
  line("WiRe Rewired " .. tostring(manifest.version), colors.lightBlue)
  line("DEVELOPMENT INSTALLER", colors.yellow)
  print("")
  for i = 1, #order do
    local package = manifest.packages[order[i]]
    print(tostring(i) .. ") " .. package.label)
  end
  print(tostring(#order + 1) .. ") Exit")
  print("")
  write("Select: ")
  local n = tonumber(read())
  if n == #order + 1 then return nil end
  return n and order[n] or nil
end

if not http then error("HTTP API is not enabled in CC:Tweaked.", 0) end

clear()
line("WiRe Rewired Development Installer", colors.lightBlue)
line("This installs from the DEVELOPMENT branch, not main.", colors.yellow)
print("")

local manifest = loadManifest()
local requested = args[1]
local unattended = args[2] == "--unattended"
local key = requested and manifest.packages[requested] and requested or choosePackage(manifest)
if not key then
  line("Installation cancelled.", colors.orange)
  return
end

local package = manifest.packages[key]
clear()
line("Installing " .. package.label, colors.yellow)
print("Version: " .. tostring(manifest.version))
print("Branch : " .. tostring(manifest.branch))
print("")

installFiles(manifest, package)
saveComponent(package.component)
local startup = installStartup(package.component, unattended)

print("")
line("Installation complete.", colors.green)
print("Installed: " .. package.label)
print("Version  : " .. tostring(manifest.version))
if package.component then
  print("Component: " .. package.component)
  print("Startup  : " .. (startup and "enabled" or "not changed"))
  print("")
  print("Run now with:")
  print("wire/runtime/launcher.lua " .. package.component)
else
  print("")
  print("Full package installed. Launch a component with:")
  print("wire/runtime/launcher.lua server")
  print("wire/runtime/launcher.lua client")
  print("wire/runtime/launcher.lua trigger")
  print("wire/runtime/launcher.lua sensor")
  print("wire/runtime/launcher.lua tablet")
end
