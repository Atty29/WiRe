-- WiRe Rewired update check diagnostics
local VERSION_FILE = "wire/shared/version.lua"
local STORAGE_FILE = "wire/shared/storage.lua"

if not fs.exists(VERSION_FILE) then error("Missing " .. VERSION_FILE, 0) end
if not fs.exists(STORAGE_FILE) then error("Missing " .. STORAGE_FILE, 0) end

local version = dofile(VERSION_FILE)
local storage = dofile(STORAGE_FILE)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("WiRe Rewired Update Check")
print("")
print("Installed: " .. tostring(version.version))

if not http then
  term.setTextColor(colors.red)
  print("HTTP API is unavailable on this computer.")
  return
end

for attempt = 1, 3 do
  local url = version.versionUrl(true)
  print("Attempt " .. attempt .. ": checking development channel...")
  local ok, response, err = pcall(http.get, url, { ["Cache-Control"] = "no-cache" })
  if ok and response then
    local remote = storage.trim(response.readAll())
    response.close()
    print("Remote: " .. tostring(remote))
    if remote ~= "" then
      if version.isDifferent(remote) then
        term.setTextColor(colors.yellow)
        print("UPDATE AVAILABLE")
      else
        term.setTextColor(colors.green)
        print("Already current.")
      end
      term.setTextColor(colors.white)
      return
    end
    print("Empty response.")
  else
    print("Request failed: " .. tostring(err or response))
  end
  sleep(attempt)
end

term.setTextColor(colors.red)
print("Unable to obtain the development version after 3 attempts.")
term.setTextColor(colors.white)
