-- WiRe Rewired team configuration utility

local TEAM_MODULE = "wire/shared/team.lua"
if not fs.exists(TEAM_MODULE) then error("Missing " .. TEAM_MODULE, 0) end
local team = dofile(TEAM_MODULE)

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function show(cfg)
  term.clear()
  term.setCursorPos(1, 1)
  print("WiRe Rewired - Team Configuration")
  print("")
  print("Current: " .. (cfg and team.describe(cfg) or "Not configured"))
  print("")
  print("1) Set/change team")
  print("2) Use legacy non-team WiRe network")
  print("3) Show network namespace")
  print("4) Exit")
  print("")
end

local cfg = team.load() or team.defaults()
while true do
  show(cfg)
  write("Select: ")
  local choice = trim(read())

  if choice == "1" then
    write("Team name: ")
    local name = trim(read())
    if name ~= "" then
      cfg = team.normalise({ enabled = true, name = name, slug = name })
      local ok, err = team.save(cfg)
      if not ok then error(err, 0) end
      print("Saved " .. team.describe(cfg))
      sleep(1)
    end
  elseif choice == "2" then
    cfg = team.normalise({ enabled = false, name = "LEGACY", slug = "LEGACY" })
    local ok, err = team.save(cfg)
    if not ok then error(err, 0) end
    print("Team isolation disabled. This computer now uses legacy WiRe networks.")
    sleep(1.5)
  elseif choice == "3" then
    print("")
    if cfg.enabled then
      print("Example Purple protocol:")
      print(team.protocol(cfg, "WiRePurple"))
      print("")
      print("Every ComputerCraft colour is available inside this team,")
      print("giving the team up to 16 isolated WiRe server colour slots.")
    else
      print("Legacy mode leaves WiRe protocols unchanged.")
    end
    print("")
    write("Press Enter...")
    read()
  elseif choice == "4" then
    term.clear()
    term.setCursorPos(1, 1)
    return
  end
end
