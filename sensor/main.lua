--==============================================================--
--                          WiRe Sensor                         --
--==============================================================--
-- Original WiRe created by Dog (HydrantHunter)                 --
-- Wi = Wireless | Re = Redstone                                --
-- Original WiRe: Pastebin hqpRw4Jy                             --
--                                                              --
-- WiRe Development Edition                                     --
-- Extensively redesigned and expanded by the WiRe Project.     --
--                                                              --
-- Module: Sensor                                                --
-- Reads local redstone or a Redstone Integrator and sends       --
-- configured redstone level events to the WiRe Server.          --
--==============================================================--

local VERSION = "0.1.0-dev"
local CONFIG_FILE = "/wire/sensor.cfg"
local DEFAULT_CHANNEL = 65530
local POLL_DELAY = 0.10

local SIDES = {"front", "back", "left", "right", "top", "bottom"}
local ACTIONS = {"open", "close", "toggle", "on", "off", "activate", "deactivate"}
local TARGET_TYPES = {"device", "group"}

local COLOUR_OPTIONS = {
    {key="w", name="White", code="white"},
    {key="o", name="Orange", code="orange"},
    {key="m", name="Magenta", code="magenta"},
    {key="l", name="Light Blue", code="lightBlue"},
    {key="y", name="Yellow", code="yellow"},
    {key="g", name="Lime", code="lime"},
    {key="p", name="Pink", code="pink"},
    {key="a", name="Gray", code="gray"},
    {key="s", name="Light Gray", code="lightGray"},
    {key="c", name="Cyan", code="cyan"},
    {key="u", name="Purple", code="purple"},
    {key="b", name="Blue", code="blue"},
    {key="r", name="Brown", code="brown"},
    {key="e", name="Green", code="green"},
    {key="d", name="Red", code="red"},
    {key="k", name="Black", code="black"}
}

local cfg = nil

local function isColour()
    return term.isColor and term.isColor()
end

local function setText(c)
    if isColour() and c then term.setTextColor(c) end
end

local function setBg(c)
    if isColour() and c then term.setBackgroundColor(c) end
end

local function clear()
    setBg(colors.black)
    setText(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function cprint(text, col)
    setText(col or colors.white)
    print(text or "")
    setText(colors.white)
end

local function writeCentered(y, text, col)
    local w = term.getSize()
    term.setCursorPos(math.max(1, math.floor((w - #text) / 2) + 1), y)
    setText(col or colors.white)
    write(text)
    setText(colors.white)
end

local function header(title, subtitle)
    clear()
    local w = term.getSize()
    setText(colors.purple)
    print(string.rep("=", w))
    writeCentered(2, title or "WiRe Sensor", colors.white)
    setText(colors.purple)
    print(string.rep("=", w))
    setText(colors.white)
    if subtitle and subtitle ~= "" then
        cprint(subtitle, colors.lightGray)
        print()
    else
        print()
    end
end

local function pause(message)
    print()
    cprint(message or "Press Enter to continue...", colors.lightGray)
    read()
end

local function ask(prompt, default)
    if default ~= nil and default ~= "" then
        write(prompt .. " [" .. tostring(default) .. "]: ")
    else
        write(prompt .. ": ")
    end
    local v = read()
    if v == "" and default ~= nil then return default end
    return v
end

local function askYesNo(question, defaultNo)
    while true do
        write(question .. (defaultNo and " [y/N]: " or " [Y/n]: "))
        local answer = string.lower(read())
        if answer == "" then return not defaultNo end
        if answer == "y" or answer == "yes" then return true end
        if answer == "n" or answer == "no" then return false end
    end
end

local function askNumber(prompt, min, max, default)
    while true do
        local n = tonumber(ask(prompt, default))
        if n and n >= min and n <= max then return n end
        cprint("Enter a number from " .. min .. " to " .. max .. ".", colors.red)
    end
end

local function askMenu(title, options, subtitle)
    while true do
        header(title, subtitle)
        for i, item in ipairs(options) do
            local label = item
            if type(item) == "table" then label = item.label or item.name or tostring(item[1]) end
            print(i .. ". " .. label)
        end
        print()
        local n = tonumber(ask("Select"))
        if n and options[n] then return n, options[n] end
        cprint("Invalid option.", colors.red)
        sleep(0.8)
    end
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
    local t = textutils.unserialize(data)
    if type(t) == "table" then return t end
    return nil
end

local function normaliseColour(name)
    name = tostring(name or "")
    name = name:gsub("%s+", "")
    if name == "lightblue" then return "lightBlue" end
    if name == "lightgray" or name == "lightgrey" then return "lightGray" end
    return string.lower(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

local function colourNameFromCode(code)
    for _, item in ipairs(COLOUR_OPTIONS) do
        if item.code == code then return item.name end
    end
    return tostring(code or "unknown")
end

local function pickColour(default)
    while true do
        header("WiRe Sensor Setup", "Choose the WiRe server colour/network this Sensor belongs to.")
        for i, item in ipairs(COLOUR_OPTIONS) do
            local marker = (item.code == default) and " *" or ""
            print(string.format("%2d. %-10s [%s]%s", i, item.name, item.key, marker))
        end
        print()
        cprint("Tip: Purple uses U because Pink uses P.", colors.lightGray)
        print()
        write("Colour number/key/name: ")
        local v = string.lower(read())

        if v == "" and default then return default end

        local n = tonumber(v)
        if n and COLOUR_OPTIONS[n] then return COLOUR_OPTIONS[n].code end

        for _, item in ipairs(COLOUR_OPTIONS) do
            if v == item.key or v == string.lower(item.name) or v == string.lower(item.code) then
                return item.code
            end
        end

        cprint("Unknown colour.", colors.red)
        sleep(0.8)
    end
end

local function getModem()
    local modem = peripheral.find("modem", function(_, m)
        return m.isWireless and m.isWireless()
    end)
    if modem then return modem end
    return peripheral.find("modem")
end

local function listRedstoneIntegrators()
    local found = {}
    for _, name in ipairs(peripheral.getNames()) do
        local pType = peripheral.getType(name) or ""
        local p = peripheral.wrap(name)
        local lowerType = string.lower(pType)
        local ok = false
        if string.find(lowerType, "redstone") then ok = true end
        if p and type(p.getAnalogInput) == "function" then ok = true end
        if ok then table.insert(found, {name = name, pType = pType}) end
    end
    table.sort(found, function(a, b) return a.name < b.name end)
    return found
end

local function readSignalFromInput(input)
    if not input then return 0 end

    if input.mode == "local" then
        return redstone.getAnalogInput(input.side) or 0
    end

    if input.mode == "integrator" then
        local p = peripheral.wrap(input.peripheral)
        if not p then return 0 end

        if type(p.getAnalogInput) == "function" then
            local ok, value = pcall(p.getAnalogInput, input.side)
            if ok and type(value) == "number" then return math.max(0, math.min(15, value)) end
        end

        if type(p.getInput) == "function" then
            local ok, value = pcall(p.getInput, input.side)
            if ok then return value and 15 or 0 end
        end
    end

    return 0
end

local function readSignal()
    if not cfg then return 0 end
    return readSignalFromInput(cfg.input)
end

local function setupIntro()
    header("WiRe Sensor Setup", "Wireless redstone input monitor")
    cprint("This setup will create one WiRe Sensor.", colors.white)
    print()
    print("A Sensor watches one redstone input and sends an event")
    print("to the WiRe Server when the signal level changes.")
    print()
    cprint("No event set for a level = that level is disabled.", colors.lightGray)
    pause()
end

local function setupIdentity(existing)
    header("WiRe Sensor Setup", "Sensor identity")
    print("Short name, max 12 chars.")
    print("Example: GATE-SENS")
    print()
    local shortName = ask("Short name", existing and existing.shortName or nil)
    while shortName == "" do
        cprint("Short name cannot be empty.", colors.red)
        shortName = ask("Short name")
    end
    shortName = string.sub(shortName, 1, 12)

    header("WiRe Sensor Setup", "Sensor description")
    print("Long description.")
    print("Example: Stargate redstone output sensor")
    print()
    local description = ask("Description", existing and existing.description or nil)
    if description == "" then description = shortName end

    return shortName, description
end

local function setupNetwork(existing)
    local serverColour = pickColour(existing and existing.serverColour or "purple")

    header("WiRe Sensor Setup", "Network channel")
    print("Use the same WiRe channel as your server.")
    print("Leave blank for default unless your WiRe server uses a custom one.")
    print()
    local channel = askNumber("WiRe channel", 1, 65535, existing and existing.channel or DEFAULT_CHANNEL)
    return serverColour, channel
end

local function pickSide(default)
    local options = {}
    for _, s in ipairs(SIDES) do table.insert(options, s) end
    local idxDefault = nil
    for i, s in ipairs(SIDES) do if s == default then idxDefault = i end end
    while true do
        header("WiRe Sensor Setup", "Choose input side")
        for i, s in ipairs(SIDES) do
            local mark = (i == idxDefault) and " *" or ""
            print(i .. ". " .. s .. mark)
        end
        print()
        local raw = ask("Select", idxDefault)
        local n = tonumber(raw)
        if n and SIDES[n] then return SIDES[n] end
        raw = string.lower(tostring(raw or ""))
        for _, s in ipairs(SIDES) do if raw == s then return s end end
    end
end

local function setupInput(existing)
    local idx, option = askMenu("WiRe Sensor Setup", {
        "Local Redstone",
        "Redstone Integrator / Wired Peripheral"
    }, "Input mode")

    if idx == 1 then
        local side = pickSide(existing and existing.input and existing.input.side or "back")
        return {mode = "local", side = side}
    end

    while true do
        local found = listRedstoneIntegrators()
        if #found == 0 then
            header("WiRe Sensor Setup", "No Redstone Integrator found")
            cprint("No compatible redstone peripheral was found.", colors.red)
            print()
            print("Check that:")
            print("- The Redstone Integrator is connected with a wired modem.")
            print("- The wired modem is enabled.")
            print("- The Sensor computer is on the same wired network.")
            print()
            if askYesNo("Retry search?", false) then
                -- loop
            else
                return setupInput(existing)
            end
        else
            local options = {}
            for _, p in ipairs(found) do
                table.insert(options, p.name .. " (" .. p.pType .. ")")
            end
            local pidx = askMenu("WiRe Sensor Setup", options, "Select Redstone Integrator")
            local side = pickSide(existing and existing.input and existing.input.side or "back")
            return {mode = "integrator", peripheral = found[pidx].name, side = side}
        end
    end
end

local function testInput(input)
    while true do
        header("WiRe Sensor Setup", "Test input")
        print("Input Mode : " .. tostring(input.mode))
        if input.peripheral then print("Peripheral : " .. tostring(input.peripheral)) end
        print("Side       : " .. tostring(input.side))
        print()
        local level = readSignalFromInput(input)
        cprint("Current Redstone Level: " .. tostring(level), colors.yellow)
        print()
        print("Press Enter to refresh.")
        print("Type C to continue, B to go back.")
        local v = string.lower(read())
        if v == "c" or v == "continue" then return true end
        if v == "b" or v == "back" then return false end
    end
end

local function targetTypeLabel(value)
    if value == "device" then return "Device" end
    if value == "group" then return "Group" end
    return tostring(value or "?")
end

local function eventSummary(level)
    if not cfg or not cfg.events then return "Disabled" end
    local event = cfg.events[level]
    if not event or type(event.actions) ~= "table" or #event.actions == 0 then
        return "Disabled"
    end
    local a = event.actions[1]
    local text = targetTypeLabel(a.targetType) .. ": " .. tostring(a.target) .. " / " .. tostring(a.command)
    if #event.actions > 1 then text = text .. " +" .. tostring(#event.actions - 1) end
    return text
end

local function addAction(level)
    local _, targetType = askMenu("Level " .. level, {"device", "group"}, "Action target type")

    header("Level " .. level, "Target")
    print("Enter the exact WiRe device ID or group name.")
    print()
    print("Examples:")
    print("L28 N-01")
    print("Security Doors")
    print()
    local target = ask("Target")
    while target == "" do
        cprint("Target cannot be empty.", colors.red)
        target = ask("Target")
    end

    local _, command = askMenu("Level " .. level, ACTIONS, "Action command")

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
        header("WiRe Sensor Events", "Redstone Level " .. tostring(level))
        print("Current: " .. eventSummary(level))
        print()
        if eventSummary(level) == "Disabled" then
            print("1. Add action")
            print("2. Back")
            print()
            local choice = ask("Select")
            if choice == "1" then addAction(level)
            elseif choice == "2" then return end
        else
            print("1. Add another action")
            print("2. Clear / disable this level")
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
end

local function editEvents()
    while true do
        header("WiRe Sensor Events", "One event per redstone level")
        for i = 0, 15 do
            local summary = eventSummary(i)
            if summary == "Disabled" then setText(colors.gray) else setText(colors.green) end
            print(string.format("%2d. %s", i, summary))
            setText(colors.white)
        end
        print()
        print("Enter level 0-15 to edit, or B to go back.")
        local choice = string.lower(ask("Level"))
        if choice == "b" or choice == "back" then return end
        local n = tonumber(choice)
        if n and n >= 0 and n <= 15 then editLevel(n) end
    end
end

local function newConfig(existing)
    setupIntro()
    local shortName, description = setupIdentity(existing)
    local serverColour, channel = setupNetwork(existing)

    local input
    while true do
        input = setupInput(existing)
        if testInput(input) then break end
    end

    cfg = {
        version = VERSION,
        shortName = shortName,
        description = description,
        serverColour = serverColour,
        channel = channel,
        input = input,
        events = existing and existing.events or {}
    }

    saveConfig()

    header("WiRe Sensor Setup", "Setup complete")
    print("Short Name : " .. cfg.shortName)
    print("Description: " .. cfg.description)
    print("Server     : " .. colourNameFromCode(cfg.serverColour))
    print("Channel    : " .. tostring(cfg.channel))
    print("Input      : " .. cfg.input.mode .. " / " .. tostring(cfg.input.side))
    if cfg.input.peripheral then print("Peripheral : " .. tostring(cfg.input.peripheral)) end
    print()
    if askYesNo("Configure redstone level events now?", false) then
        editEvents()
    end
end

local function sendToServer(packet)
    local modem = getModem()
    if not modem then
        return false, "No modem found"
    end

    if not modem.isOpen(cfg.channel) then modem.open(cfg.channel) end

    packet.wire = true
    packet.module = "sensor"
    packet.sensor = cfg.shortName
    packet.description = cfg.description
    packet.serverColour = cfg.serverColour

    modem.transmit(cfg.channel, cfg.channel, packet)
    return true
end

local function runAction(level, action)
    return sendToServer({
        type = "SENSOR_ACTION",
        level = level,
        targetType = action.targetType,
        target = action.target,
        command = action.command
    })
end

local function executeLevel(level)
    local event = cfg.events and cfg.events[level]
    if not event or type(event.actions) ~= "table" or #event.actions == 0 then return end

    for _, action in ipairs(event.actions) do
        runAction(level, action)
        sleep(0.05)
    end
end

local function showStatus()
    while true do
        header("WiRe Sensor Status", cfg.shortName .. " - " .. cfg.description)
        print("Server Colour : " .. colourNameFromCode(cfg.serverColour))
        print("WiRe Channel  : " .. tostring(cfg.channel))
        print("Input Mode    : " .. tostring(cfg.input.mode))
        if cfg.input.peripheral then print("Peripheral    : " .. tostring(cfg.input.peripheral)) end
        print("Input Side    : " .. tostring(cfg.input.side))
        print()
        local level = readSignal()
        cprint("Current Signal: " .. tostring(level), colors.yellow)
        print("Level Event   : " .. eventSummary(level))
        print()
        print("Press Enter to refresh, B to go back.")
        local v = string.lower(read())
        if v == "b" or v == "back" then return end
    end
end

local function changeInput()
    local input
    while true do
        input = setupInput(cfg)
        if testInput(input) then break end
    end
    cfg.input = input
    saveConfig()
end

local function changeServerColour()
    cfg.serverColour = pickColour(cfg.serverColour)
    saveConfig()
end

local function monitor()
    header("WiRe Sensor", "Monitoring")
    cprint("Press Ctrl+T to stop.", colors.lightGray)
    sleep(1)

    local lastLevel = nil
    while true do
        local level = readSignal()
        if level ~= lastLevel then
            lastLevel = level
            executeLevel(level)
        end

        clear()
        cprint("WiRe Sensor", colors.purple)
        print(cfg.shortName .. " - " .. cfg.description)
        print()
        print("Server : " .. colourNameFromCode(cfg.serverColour))
        print("Input  : " .. cfg.input.mode .. " / " .. tostring(cfg.input.side))
        if cfg.input.peripheral then print("Periph : " .. tostring(cfg.input.peripheral)) end
        print()
        cprint("Current Signal: " .. tostring(level), colors.yellow)
        print("Event: " .. eventSummary(level))
        print()
        cprint("Ctrl+T to terminate", colors.gray)
        sleep(POLL_DELAY)
    end
end

local function mainMenu()
    while true do
        header("WiRe Sensor", cfg.shortName .. " - " .. cfg.description)
        print("1. Start monitoring")
        print("2. View current signal")
        print("3. Edit redstone level events")
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
        elseif choice == "6" then newConfig(cfg)
        elseif choice == "7" then clear(); return end
    end
end

cfg = loadConfig()
if not cfg then
    newConfig(nil)
end
mainMenu()
