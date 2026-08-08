--==============================================================--
--                   WiRe Rewired Launcher                     --
--==============================================================--
-- Development runtime wrapper.
--
-- Provides features around the proven WiRe programs without rewriting their
-- working discovery/encryption code:
--   * Team network namespaces (16 colour servers per team)
--   * Development-build identification
--   * Persistent update prompt on launch
--   * Visible update reminder on the Server monitor
--   * Rewired version/team identity on legacy Server/Client terminals
--   * Shared component registry and storage helpers
--==============================================================--

local ROOT = "wire"
local VERSION_FILE = ROOT .. "/shared/version.lua"
local TEAM_FILE = ROOT .. "/shared/team.lua"
local STORAGE_FILE = ROOT .. "/shared/storage.lua"
local COMPONENTS_FILE = ROOT .. "/shared/components.lua"
local COMPONENT_FILE = ROOT .. "/component.cfg"
local UPDATE_PREFS_FILE = "/data/WiRe/update.cfg"
local launchArgs = { ... }

local function loadModule(path)
  if not fs.exists(path) then error("Missing WiRe Rewired module: " .. path, 0) end
  local ok, result = pcall(dofile, path)
  if not ok then error("Cannot load " .. path .. ": " .. tostring(result), 0) end
  return result
end

local version = loadModule(VERSION_FILE)
local team = loadModule(TEAM_FILE)
local storage = loadModule(STORAGE_FILE)
local components = loadModule(COMPONENTS_FILE)

local function askYesNo(question, defaultYes)
  while true do
    write(question .. (defaultYes and " [Y/n]: " or " [y/N]: "))
    local answer = string.lower(storage.trim(read()))
    if answer == "" then return defaultYes end
    if answer == "y" or answer == "yes" then return true end
    if answer == "n" or answer == "no" then return false end
  end
end

local function setupTeam()
  local cfg = team.load()
  if cfg then return cfg end

  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
  print("WiRe Rewired - Team Setup")
  print("")
  print("Team isolation lets different groups reuse all 16 WiRe colour")
  print("servers without seeing or controlling one another by accident.")
  print("")

  local enabled = askYesNo("Enable team isolation?", true)
  local name = team.defaultName
  if enabled then
    write("Team name (use the SAME name on this team's devices): ")
    name = storage.trim(read())
    if name == "" then name = team.defaultName end
  end

  cfg = team.normalise({ enabled = enabled, name = name, slug = name })
  local ok, err = team.save(cfg)
  if not ok then error(err, 0) end
  print("")
  print("Saved: " .. team.describe(cfg))
  sleep(1)
  return cfg
end

local function loadComponent()
  local requested = storage.trim(launchArgs[1])
  if components.isValid(requested) then return requested end

  local saved = storage.trim(storage.readText(COMPONENT_FILE, ""))
  if components.isValid(saved) then return saved end

  term.clear()
  term.setCursorPos(1, 1)
  print("WiRe Rewired component")
  for i = 1, #components.order do
    local name = components.order[i]
    print(tostring(i) .. ") " .. components.label(name))
  end
  write("Select: ")
  local index = tonumber(storage.trim(read()))
  local component = index and components.order[index] or nil
  if not components.isValid(component) then error("No valid WiRe component selected.", 0) end
  return component
end

local function loadUpdatePrefs()
  local prefs = storage.loadTable(UPDATE_PREFS_FILE, {})
  if type(prefs) ~= "table" then prefs = {} end
  if prefs.mode ~= "never" then prefs.mode = "prompt" end
  return prefs
end

local function saveUpdatePrefs(prefs)
  local ok, err = storage.saveTable(UPDATE_PREFS_FILE, prefs)
  if ok == false then
    term.setTextColor(colors.red)
    print("Could not save update preference: " .. tostring(err))
    term.setTextColor(colors.white)
  end
end

local function checkForUpdate(prefs)
  if prefs.mode == "never" or not http then return nil end
  local url = version.versionUrl(true)
  local ok, response = pcall(http.get, url, { ["Cache-Control"] = "no-cache" })
  if not ok or not response then return nil end
  local remote = storage.trim(response.readAll())
  response.close()
  if remote ~= "" and version.isDifferent(remote) then return remote end
  return nil
end

local function showMonitorUpdatePrompt(remoteVersion)
  local mon = peripheral.find("monitor")
  if not mon then return end

  local w, h = mon.getSize()
  mon.setBackgroundColor(colors.black)
  mon.setTextColor(colors.white)
  mon.clear()

  mon.setBackgroundColor(colors.yellow)
  mon.setTextColor(colors.black)
  mon.setCursorPos(1, 1)
  mon.write(string.rep(" ", w))

  local title = "WiRe Rewired Update Available"
  local titleX = math.max(1, math.floor((w - #title) / 2) + 1)
  mon.setCursorPos(titleX, 1)
  mon.write(title:sub(1, w))

  mon.setBackgroundColor(colors.black)
  mon.setTextColor(colors.white)

  local lines = {
    "Installed: " .. tostring(version.version),
    "Available: " .. tostring(remoteVersion),
    "",
    "UPDATE AVAILABLE - SEE COMPUTER",
  }

  local startY = math.max(3, math.floor((h - #lines) / 2))
  for i = 1, #lines do
    local text = lines[i]
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    if i == #lines then
      mon.setTextColor(colors.yellow)
    else
      mon.setTextColor(colors.white)
    end
    mon.setCursorPos(x, math.min(h, startY + i - 1))
    mon.write(text:sub(1, w))
  end
end

local function showUpdatePrompt(remoteVersion, prefs)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)

  term.setBackgroundColor(colors.yellow)
  term.setTextColor(colors.black)
  local w = term.getSize()
  term.write(string.rep(" ", w))
  term.setCursorPos(2, 1)
  term.write("WiRe Rewired Update Available")

  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.setCursorPos(1, 3)
  print("Installed: " .. version.version)
  print("Available: " .. tostring(remoteVersion))
  print("")
  print("1) UPDATE NOW")
  print("2) LATER - ask again next time WiRe starts")
  print("3) NEVER - stop automatic update checks")
  print("")
  term.setTextColor(colors.lightGray)
  print("Manual updates will still work if automatic checks are disabled.")
  term.setTextColor(colors.white)
  print("")

  while true do
    write("Select 1, 2 or 3: ")
    local choice = storage.trim(read())

    if choice == "1" then
      term.setTextColor(colors.yellow)
      print("Starting updater...")
      term.setTextColor(colors.white)
      local ok = shell.run(ROOT .. "/tools/update.lua")
      if ok == false then
        term.setTextColor(colors.red)
        print("Update did not complete successfully.")
        term.setTextColor(colors.white)
        print("Press Enter to continue with the installed version.")
        read()
        return "later"
      end
      print("Update complete. Rebooting into the new build...")
      sleep(2)
      os.reboot()
      return "reboot"

    elseif choice == "2" then
      return "later"

    elseif choice == "3" then
      prefs.mode = "never"
      saveUpdatePrefs(prefs)
      print("Automatic update checks disabled.")
      sleep(1)
      return "never"
    end
  end
end

local function installTeamNetworkWrapper(cfg)
  if not cfg.enabled then return function() end end

  local original = {
    host = rednet.host,
    unhost = rednet.unhost,
    lookup = rednet.lookup,
    send = rednet.send,
    broadcast = rednet.broadcast,
    receive = rednet.receive,
  }

  local function map(protocol)
    return team.protocol(cfg, protocol)
  end

  rednet.host = function(protocol, hostname)
    return original.host(map(protocol), hostname)
  end

  rednet.unhost = function(protocol, hostname)
    return original.unhost(map(protocol), hostname)
  end

  rednet.lookup = function(protocol, hostname)
    return original.lookup(map(protocol), hostname)
  end

  rednet.send = function(recipient, message, protocol)
    return original.send(recipient, message, map(protocol))
  end

  rednet.broadcast = function(message, protocol)
    return original.broadcast(message, map(protocol))
  end

  rednet.receive = function(protocol, timeout)
    return original.receive(map(protocol), timeout)
  end

  return function()
    rednet.host = original.host
    rednet.unhost = original.unhost
    rednet.lookup = original.lookup
    rednet.send = original.send
    rednet.broadcast = original.broadcast
    rednet.receive = original.receive
  end
end

local function makeHeader(component, cfg)
  local title = component == "server" and "WiRe Rewired Server" or "WiRe Rewired Client"
  local teamText = cfg.enabled and ("Team: " .. tostring(cfg.name)) or "Legacy Network"
  return title .. " " .. version.version .. " | " .. teamText
end

local function installTerminalIdentityWrapper(component, cfg)
  if component ~= "server" and component ~= "client" then return function() end end

  local originalWrite = term.write
  local modernHeader = makeHeader(component, cfg)

  term.write = function(text)
    local _, y = term.getCursorPos()
    local raw = tostring(text or "")
    local isLegacyHeader = y == 1 and (
      string.find(raw, "WiRe Server ", 1, true) or
      string.find(raw, "WiRe Client ", 1, true)
    )

    if not isLegacyHeader then return originalWrite(text) end

    local w = term.getSize()
    local shown = modernHeader
    if #shown > w then shown = shown:sub(1, w) end
    local left = math.max(0, math.floor((w - #shown) / 2))
    local right = math.max(0, w - left - #shown)
    term.setCursorPos(1, 1)
    return originalWrite(string.rep(" ", left) .. shown .. string.rep(" ", right))
  end

  return function()
    term.write = originalWrite
  end
end

local function serverUpdateReminder(remoteVersion)
  local mon = peripheral.find("monitor")
  if not mon then return end

  local label = " UPDATE AVAILABLE - SEE COMPUTER "
  while true do
    sleep(2)
    local w = mon.getSize()
    if w >= #label + 2 then
      local x = math.max(1, w - #label)
      mon.setCursorPos(x, 1)
      mon.setBackgroundColor(colors.red)
      mon.setTextColor(colors.white)
      mon.write(label)
    end
    sleep(3)
  end
end

local component = loadComponent()
local cfg = setupTeam()
local updatePrefs = loadUpdatePrefs()
local updateVersion = checkForUpdate(updatePrefs)
local updateChoice

if updateVersion then
  if component == "server" then showMonitorUpdatePrompt(updateVersion) end
  updateChoice = showUpdatePrompt(updateVersion, updatePrefs)
  if updateChoice == "never" then updateVersion = nil end
end

local target = components.path(component)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print(version.name .. "  " .. version.version)
print("DEVELOPMENT BUILD")
print("Component: " .. string.upper(component))
print("Network:   " .. team.describe(cfg))
print("")

if not target or not fs.exists(target) then
  error("Installed component file is missing: " .. tostring(component), 0)
end

sleep(1)

local restoreNetwork = installTeamNetworkWrapper(cfg)
local restoreTerminal = installTerminalIdentityWrapper(component, cfg)
local ok, result

if component == "server" and updateVersion then
  ok, result = pcall(function()
    parallel.waitForAny(
      function() return shell.run(target) end,
      function() return serverUpdateReminder(updateVersion) end
    )
  end)
else
  ok, result = pcall(shell.run, target)
end
restoreTerminal()
restoreNetwork()

if not ok then
  term.setTextColor(colors.red)
  print("WiRe Rewired component crashed:")
  print(tostring(result))
  term.setTextColor(colors.white)
  error(result, 0)
elseif result == false then
  term.setTextColor(colors.red)
  print("WiRe Rewired component returned an error.")
  term.setTextColor(colors.white)
end
