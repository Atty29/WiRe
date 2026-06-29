--==============================================================--
--                         WiRe Installer                       --
--==============================================================--
-- WiRe Development Edition                                     --
-- Downloads WiRe components from GitHub for CC:Tweaked.        --
--==============================================================--

local REPO_USER = "Atty29"
local REPO_NAME = "WiRe"
local BRANCH = "main"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPO_USER .. "/" .. REPO_NAME .. "/" .. BRANCH .. "/"

local INSTALL_DIR = "wire"

local packages = {
    server = {
        title = "WiRe Server",
        source = "server/main.lua",
        target = INSTALL_DIR .. "/server.lua",
        startup = "shell.run(\"" .. INSTALL_DIR .. "/server.lua\")"
    },
    client = {
        title = "WiRe Client",
        source = "client/main.lua",
        target = INSTALL_DIR .. "/client.lua",
        startup = "shell.run(\"" .. INSTALL_DIR .. "/client.lua\")"
    },
    trigger = {
        title = "WiRe Trigger",
        source = "trigger/main.lua",
        target = INSTALL_DIR .. "/trigger.lua",
        startup = "shell.run(\"" .. INSTALL_DIR .. "/trigger.lua\")"
    }
}

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function writeLine(text, colour)
    if colour then term.setTextColor(colour) end
    print(text)
    term.setTextColor(colors.white)
end

local function pause()
    print()
    write("Press Enter to continue...")
    read()
end

local function checkHttp()
    if not http then
        writeLine("HTTP API is not enabled.", colors.red)
        print("Enable HTTP in the ComputerCraft/CC:Tweaked config.")
        return false
    end
    return true
end

local function downloadFile(sourcePath, targetPath)
    local url = BASE_URL .. sourcePath
    writeLine("Downloading:", colors.lightBlue)
    print(url)
    print("-> " .. targetPath)

    local response, err = http.get(url)
    if not response then
        writeLine("Download failed: " .. tostring(err), colors.red)
        return false
    end

    local data = response.readAll()
    response.close()

    local folder = fs.getDir(targetPath)
    if folder ~= "" and not fs.exists(folder) then
        fs.makeDir(folder)
    end

    local file = fs.open(targetPath, "w")
    file.write(data)
    file.close()

    writeLine("Installed " .. targetPath, colors.green)
    return true
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

local function createStartup(pkg)
    if fs.exists("startup.lua") then
        writeLine("startup.lua already exists.", colors.orange)
        if not askYesNo("Replace startup.lua so this starts automatically?", true) then
            return
        end
    else
        if not askYesNo("Start " .. pkg.title .. " automatically on boot?", false) then
            return
        end
    end

    local file = fs.open("startup.lua", "w")
    file.writeLine("-- WiRe auto-start file")
    file.writeLine(pkg.startup)
    file.close()

    writeLine("startup.lua created.", colors.green)
end

local function installPackage(key)
    local pkg = packages[key]
    if not pkg then return false end

    print()
    writeLine("Installing " .. pkg.title, colors.yellow)

    if fs.exists(pkg.target) then
        writeLine(pkg.target .. " already exists.", colors.orange)
        if not askYesNo("Overwrite it?", true) then
            writeLine("Skipped.", colors.orange)
            return false
        end
    end

    local ok = downloadFile(pkg.source, pkg.target)
    if ok then
        createStartup(pkg)
    end
    return ok
end

local function menu()
    while true do
        clear()
        writeLine("==============================", colors.purple)
        writeLine("        WiRe Installer        ", colors.white)
        writeLine("==============================", colors.purple)
        print()
        print("Repository:")
        print("github.com/" .. REPO_USER .. "/" .. REPO_NAME)
        print()
        print("1. Install Server")
        print("2. Install Client")
        print("3. Install Trigger")
        print("4. Exit")
        print()
        write("Select option: ")

        local choice = read()

        clear()
        if choice == "1" then
            installPackage("server")
            pause()
        elseif choice == "2" then
            installPackage("client")
            pause()
        elseif choice == "3" then
            installPackage("trigger")
            pause()
        elseif choice == "4" then
            clear()
            return
        else
            writeLine("Invalid option.", colors.red)
            pause()
        end
    end
end

clear()
if checkHttp() then
    menu()
end
