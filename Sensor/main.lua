--==============================================================--
--                          WiRe Sensor                         --
--==============================================================--
-- WiRe Development Edition                                     --
-- Reads local redstone or a Redstone Integrator and sends       --
-- configured level events to the WiRe Server.                  --
--==============================================================--

local VERSION = "0.1.0-dev"
local CONFIG_FILE = "/wire/sensor.cfg"
local DEFAULT_CHANNEL = 65530
local POLL_DELAY = 0.10

local SIDES = {"front", "back", "left", "right", "top", "bottom"}
local ACTIONS = {"open", "close", "toggle", "on", "off", "activate", "deactivate"}
local TARGET_TYPES = {"device", "group"}

local cfg = nil
local running = true

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function colour(c)
    if term.isColor and term.isColor() then term.setTextColor(c) end
end

local function writeLine(text, c)
    if c then colour(c) end
    print(text)
    colour(colors.white)
end

local function pause()
    print()
    write("Press Enter to continue...")
    read()
end

local function ensureDir(path)
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
end

local function saveConfig()
    ensureDir(CONFIG_FILE)
    local f = fs.open(CONFIG_FILE, "w")
    f.write(textutils.serialize(cfg))
    f.close()
end

local function loadConfig()
    if not fs.exists(CONFIG_FILE) then return nil end
    local f = fs.open(CONFIG_FILE, "r")
    local data = f.readAll()
    f.close()
    local ok, t = pcall(textutils.unserialize, data)
    if ok and type(t) == "table" then return t end
    return nil
end

local function ask(prompt, default)
    if default then
        write(prompt .. " [" .. tostring(default) .. "]: ")
    else
        write(prompt .. ": ")
    end
    local v = read()
    if v == "" and default ~= nil then return default end
    return v
end

local function askNumber(prompt, min, max, default)
    while true do
        local v = tonumber(ask(prompt, default))
        if v and v >= min and v <= max then return v end
        writeLine("Enter a number from " .. min .. " to " .. max .. ".", colors.red)
    end
end

local function askMenu(title, options)
    while true do
        clear()
        writeLine(title, colors.purple)
        writeLine(string.rep("=", #title), colors.purple)
        print()
        for i, item in ipairs(options) do
            print(i .. ". " .. item)
        end
        print()
        local n = tonumber(ask("Select"))
        if n and options[n] then return n, options[n] end
    end
end

local function normaliseColour(name)
    name = string.lower(tostring(name or ""))
    name = name:gsub("%s+", "")
    return name
end

local function getModem()
    local modem = peripheral.find("modem", function(_, m) return m.isWireless and m.isWireless() end)
    if modem then return modem end
    return peripheral.find("modem")
end

local function openChannel(modem, channel)
    if modem and not modem.isOpen(channel) then modem.open(channel) end
end

local function listRedstoneIntegrators()
    local found = {}
    for _, name in ipairs(peripheral.getNames()) do
        local pType = peripheral.getType(name) or ""
        local p = peripheral.wrap(name)
        local looksLikeIntegrator = false

        if string.find(string.lower(pType), "redstone") then
            looksLikeIntegrator = true
        elseif p and type(p.getAnalogInput) == "function" then
            looksLikeIntegrator = true
        end

        if looksLikeIntegrator then
            table.insert(found, {name = name, pType = pType})
        end
    end
    table.sort(found, function(a, b) return a.name < b.name end)
    return found
end

local function setupInput()
    local _, mode = askMenu("Input Mode", {
        "Local Redstone",
        "Redstone Integrator / Wired Peripheral"
    })

    if mode == "Local Redstone" then
        local _, side = askMenu("Input Side", SIDES)
        return {mode = "local", side = side}
    end

    local found = listRedstoneIntegrators()
    if #found == 0 then
        clear()
        writeLine("No Redstone Integrators found.", colors.red)
        print("Make sure it is connected with a wired modem and the modem is online.")
        pause()
        return setupInput()
    end

    local options = {}
    for _, p in ipairs(found) do
        table.insert(options, p.name .. " (" .. p.pType .. ")")
    end

    local idx = askMenu("Select Peripheral", options)
    local _, side = askMenu("Input Side", SIDES)

    return {
        mode = "integrator",
        peripheral = found[idx].name,
        side = side
    }
end

local function newConfig()
    clear()
    writeLine("WiRe Sensor Setup", colors.purple)
    writeLine("=================", colors.purple)
    print()

    local shortName = ask("Short name, max 12 chars")
    shortName = string.sub(shortName, 1, 12)
    local description = ask("Long description")
    local serverColour = normaliseColour(ask("Server colour"))
    local channel = askNumber("WiRe channel", 1, 65535, DEFAULT_CHANNEL)

    local input = setupInput()

    cfg = {
        version = VERSION,
        shortName = shortName,
        description = description,
        serverColour = serverColour,
        channel = channel,
        input = input,
        events = {}
    }

    saveConfig()
end

local function readSignal()
    if not cfg or not cfg.input then return 0 end

    if cfg.input.mode == "local" then
        return redstone.getAnalogInput(cfg.input.side) or 0
    end

    if cfg.input.mode == "integrator" then
        local p = peripheral.wrap(cfg.input.peripheral)
        if not p then return 0 end

        if type(p.getAnalogInput) == "function" then
            local ok, value = pcall(p.getAnalogInput, cfg.input.side)
            if ok and type(value) == "number" then return value end
        end

        if type(p.getInput) == "function" then
            local ok, value = pcall(p.getInput, cfg.input.side)
            if ok then return value and 15 or 0 end
        end
    end

    return 0
end

local function sendToServer(packet)
    local modem = getModem()
    if not modem then
        writeLine("No modem found.", colors.red)
        return false
    end

    packet.wire = true
    packet.module = "sensor"
    packet.sensor = cfg.shortName
    packet.description = cfg.description
    packet.serverColour = cfg.serverColour

    modem.transmit(cfg.channel, cfg.channel, packet)
    return true
end

local function runAction(level, action)
    -- This packet is intentionally generic. The server handler can translate it
    -- into the same internal command path used by WiRe Trigger and the UI.
    return sendToServer({
        type = "SENSOR_ACTION",
        level = level,
        targetType = action.targetType,
        target = action.target,
        command = action.command
    })
end

local function executeLevel(level)
    local event = cfg.events[level]
    if not event or type(event.actions) ~= "table" or #event.actions == 0 then
        return
    end

    for _, action in ipairs(event.actions) do
        runAction(level, action)
        sleep(0.05)
    end
end

local function eventSummary(level)
    local event = cfg.events[level]
    if not event or not event.actions or #event.actions == 0 then
        return "Disabled"
    end

    local a = event.actions[1]
    local text = tostring(a.targetType) .. ": " .. tostring(a.target) .. " / " .. tostring(a.command)
    if #event.actions > 1 then text = text .. " +" .. tostring(#event.actions - 1) end
    return text
end

local function addAction(level)
    clear()
    writeLine("Level " .. level .. " Action", colors.purple)
    print()

    local _, targetType = askMenu("Target Type", {"device", "group"})
    clear()
    writeLine("Target", colors.purple)
    print()
    print("Enter the exact WiRe device ID or group name.")
    print("Example: L28 N-01 or Security Doors")
    print()
    local target = ask("Target")

    local _, command = askMenu("Action", ACTIONS)

    cfg.events[level] = cfg.events[level] or {actions = {}}
    table.insert(cfg.events[level].actions, {
        targetType = targetType,
        target = target,
        command = command
    })
    saveConfig()
end

local function editLevel(level)
    while true do
        clear()
        writeLine("Redstone Level " .. level, colors.purple)
        writeLine("=================", colors.purple)
        print()
        print("Current: " .. eventSummary(level))
        print()
        print("1. Add action")
        print("2. Clear/disable this level")
        print("3. Back")
        print()
        local choice = ask("Select")

        if choice == "1" then
            addAction(level)
        elseif choice == "2" then
            cfg.events[level] = nil
            saveConfig()
        elseif choice == "3" then
            return
        end
    end
end

local function editEvents()
    while true do
        clear()
        writeLine("WiRe Sensor Events", colors.purple)
        writeLine("==================", colors.purple)
        print()
        for i = 0, 15 do
            local status = eventSummary(i)
            if status == "Disabled" then colour(colors.gray) else colour(colors.green) end
            print(string.format("%2d  %s", i, status))
            colour(colors.white)
        end
        print()
        print("Enter 0-15 to edit, or B to go back.")
        local choice = string.lower(ask("Level"))
        if choice == "b" or choice == "back" then return end
        local n = tonumber(choice)
        if n and n >= 0 and n <= 15 then editLevel(n) end
    end
end

local function showStatus()
    while true do
        clear()
        writeLine("WiRe Sensor Status", colors.purple)
        writeLine("==================", colors.purple)
        print()
        print("Name       : " .. tostring(cfg.shortName))
        print("Desc       : " .. tostring(cfg.description))
        print("Colour     : " .. tostring(cfg.serverColour))
        print("Channel    : " .. tostring(cfg.channel))
        print("Input Mode : " .. tostring(cfg.input.mode))
        if cfg.input.peripheral then print("Peripheral : " .. tostring(cfg.input.peripheral)) end
        print("Side       : " .. tostring(cfg.input.side))
        print()
        local level = readSignal()
        print("Current Signal: " .. tostring(level))
        print("Event         : " .. eventSummary(level))
        print()
        print("Press Enter to refresh, B to go back.")
        local v = string.lower(read())
        if v == "b" or v == "back" then return end
    end
end

local function changeInput()
    cfg.input = setupInput()
    saveConfig()
end

local function changeServerColour()
    clear()
    cfg.serverColour = normaliseColour(ask("Server colour", cfg.serverColour))
    saveConfig()
end

local function monitor()
    clear()
    writeLine("WiRe Sensor Running", colors.green)
    print("Press Ctrl+T to terminate.")
    sleep(1)

    local lastLevel = nil
    while true do
        local level = readSignal()
        if level ~= lastLevel then
            lastLevel = level
            executeLevel(level)
        end

        term.setCursorPos(1, 1)
        term.clearLine()
        colour(colors.purple)
        write("WiRe Sensor ")
        colour(colors.white)
        write(cfg.shortName .. " | Level: " .. tostring(level) .. " | " .. eventSummary(level))
        sleep(POLL_DELAY)
    end
end

local function mainMenu()
    while running do
        clear()
        writeLine("WiRe Sensor", colors.purple)
        writeLine("===========", colors.purple)
        print()
        print("1. Start monitoring")
        print("2. View current signal")
        print("3. Edit level events")
        print("4. Change input source")
        print("5. Change server colour")
        print("6. Re-run setup")
        print("7. Exit")
        print()
        local choice = ask("Select")

        if choice == "1" then monitor()
        elseif choice == "2" then showStatus()
        elseif choice == "3" then editEvents()
        elseif choice == "4" then changeInput()
        elseif choice == "5" then changeServerColour()
        elseif choice == "6" then newConfig()
        elseif choice == "7" then running = false end
    end
end

cfg = loadConfig()
if not cfg then newConfig() end
mainMenu()
