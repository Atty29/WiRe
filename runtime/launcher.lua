--==============================================================--
--                   WiRe Rewired Launcher                     --
--==============================================================--
-- Development runtime wrapper.
--
-- Provides features around the proven WiRe programs without rewriting their
-- working discovery/encryption code:
--   * Team network namespaces (16 colour servers per team)
--   * Development-build identification
--   * Non-blocking update notification
--   * One consistent component launcher
--==============================================================--

local ROOT = "wire"
local VERSION_FILE = ROOT .. "/shared/version.lua"
local TEAM_FILE = ROOT .. "/shared/team.lua"
local COMPONENT_FILE = ROOT .. "/component.cfg"

local function loadModule(path)
  if not fs.exists(path) then error("Missing WiRe Rewired module: " .. path, 0) end
  local ok, result = pcall(dofile, path)
  if not ok then error("Cannot load " .. path .. ": " .. tostring(result), 0) end
  return result
end

local version = loadModule(VERSION_FILE)
local team = loadModule(TEAM_FILE)

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function askYesNo(question, defaultYes)
  while true do
    write(question .. (defaultYes and " [Y/n]: " or " [y/N]: "))
    local answer = string.lower(trim(read()))
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
    name = trim(read())
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
  local args = { ... }
  local requested = args[1]
  local valid = {
    server = true,
    client = true,
    trigger = true,
    sensor = true,
    tablet = true,
  }
  if requested and valid[requested] then return requested end

  if fs.exists(COMPONENT_FILE) then
    local f = fs.open(COMPONENT_FILE, "r")
    if f then
      local saved = trim(f.readAll())
      f.close()
      if valid[saved] then return saved end
    end
  end

  term.clear()
  term.setCursorPos(1, 1)
  print("WiRe Rewired component")
  print("1) Server")
  print("2) Client")
  print("3) Trigger")
  print("4) Sensor")
  print("5) Tablet")
  write("Select: ")
  local map = { ["1"] = "server", ["2"] = "client", ["3"] = "trigger", ["4"] = "sensor", ["5"] = "tablet" }
  local component = map[trim(read())]
  if not component then error("No valid WiRe component selected.", 0) end
  return component
end

local function checkForUpdate()
  if not http then return nil end
  local response = http.get(version.versionUrl())
  if not response then return nil end
  local remote = trim(response.readAll())
  response.close()
  if remote ~= "" and version.isDifferent(remote) then return remote end
  return nil
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

local function componentPath(component)
  local flat = ROOT .. "/" .. component .. ".lua"
  if fs.exists(flat) then return flat end
  local structured = ROOT .. "/" .. component .. "/main.lua"
  if fs.exists(structured) then return structured end
  return nil
end

local component = loadComponent()
local cfg = setupTeam()
local updateVersion = checkForUpdate()
local target = componentPath(component)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print(version.name .. "  " .. version.version)
print("DEVELOPMENT BUILD")
print("Component: " .. string.upper(component))
print("Network:   " .. team.describe(cfg))
if updateVersion then
  term.setTextColor(colors.yellow)
  print("Update available: " .. updateVersion)
  print("Run: wire/tools/update.lua")
  term.setTextColor(colors.white)
end
print("")

if not target then
  error("Installed component file is missing: " .. component, 0)
end

sleep(updateVersion and 2 or 1)

local restoreNetwork = installTeamNetworkWrapper(cfg)
local ok, result = pcall(shell.run, target)
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
