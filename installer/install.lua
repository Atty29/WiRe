-- WiRe Installer
-- Put this file on Pastebin, then users run: pastebin run <code>

local REPO_RAW = "https://raw.githubusercontent.com/Atty29/WiRe/main/"
local MANIFEST_URL = REPO_RAW .. "manifest.lua"

local function clear()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
end

local function ensureDir(path)
  local parts = {}
  for part in string.gmatch(path, "[^/]+") do table.insert(parts, part) end
  if #parts <= 1 then return end
  local current = ""
  for i = 1, #parts - 1 do
    current = current == "" and parts[i] or (current .. "/" .. parts[i])
    if not fs.exists(current) then fs.makeDir(current) end
  end
end

local function download(url, dest)
  print("Downloading " .. dest)
  local h = http.get(url)
  if not h then error("Failed to download: " .. url) end
  local data = h.readAll()
  h.close()
  ensureDir(dest)
  if fs.exists(dest) then fs.delete(dest) end
  local f = fs.open(dest, "w")
  f.write(data)
  f.close()
end

local function loadManifest()
  local h = http.get(MANIFEST_URL)
  if not h then
    error("Could not reach GitHub. Is HTTP enabled in CC:Tweaked config?")
  end
  local code = h.readAll()
  h.close()
  local fn, err = load(code, "manifest", "t", {})
  if not fn then error(err) end
  return fn()
end

local function makeStartup(target)
  if fs.exists("startup.lua") then
    print("startup.lua already exists, leaving it alone.")
    return
  end
  local f = fs.open("startup.lua", "w")
  f.writeLine("shell.run(\"" .. target .. "\")")
  f.close()
  print("Created startup.lua -> " .. target)
end

clear()
print("==============================")
print("         WiRe Installer")
print("==============================")
print("")

local manifest = loadManifest()
print("Latest version: " .. tostring(manifest.version))
print("")
print("1. Install Server")
print("2. Install Client")
print("3. Install Trigger")
print("4. Install Tablet")
print("5. Install Full Package")
print("6. Update Existing / Repair")
print("")
write("Select option: ")
local choice = read()

local keyMap = {
  ["1"] = "server",
  ["2"] = "client",
  ["3"] = "trigger",
  ["4"] = "tablet",
  ["5"] = "full",
  ["6"] = "full",
}

local key = keyMap[choice]
if not key or not manifest.packages[key] then
  print("Invalid option.")
  return
end

local package = manifest.packages[key]
print("")
print("Installing: " .. package.label)
print("")

local baseUrl = manifest.baseUrl or REPO_RAW
for _, file in ipairs(package.files) do
  download(baseUrl .. file.src, file.dest)
end

print("")
print("Install complete.")

if package.startup then
  write("Auto-run this package on boot? Y/N: ")
  local ans = string.lower(read() or "")
  if ans == "y" or ans == "yes" then
    makeStartup(package.startup)
  end
  print("")
  print("Run now with:")
  print(package.startup)
  print("")
  write("Run now? Y/N: ")
  local runNow = string.lower(read() or "")
  if runNow == "y" or runNow == "yes" then
    shell.run(package.startup)
  end
else
  print("Full package installed. Run one of:")
  print("wire/server/main.lua")
  print("wire/client/main.lua")
  print("wire/trigger/main.lua")
  print("wire/tablet/main.lua")
end
