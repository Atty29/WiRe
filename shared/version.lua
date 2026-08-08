-- WiRe Rewired shared version helper

local version = {
  name = "WiRe Rewired",
  version = "3.3.6-dev",
  channel = "development",
  repoUser = "Atty29",
  repoName = "WiRe",
  branch = "development",
}

function version.rawBaseUrl()
  return "https://raw.githubusercontent.com/" .. version.repoUser .. "/" .. version.repoName .. "/" .. version.branch .. "/"
end

function version.versionUrl(cacheBust)
  local url = version.rawBaseUrl() .. "version.txt"
  if cacheBust then
    local stamp
    if os.epoch then
      local ok, value = pcall(os.epoch, "utc")
      if ok then stamp = value end
    end
    stamp = stamp or math.floor((os.time() or 0) * 1000)
    url = url .. "?wire_check=" .. tostring(stamp)
  end
  return url
end

function version.trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function version.isDifferent(remoteVersion)
  return version.trim(remoteVersion) ~= version.version
end

return version
