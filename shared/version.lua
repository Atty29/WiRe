-- WiRe Rewired shared version helper

local version = {
  name = "WiRe Rewired",
  version = "3.2.1-dev",
  channel = "development",
  repoUser = "Atty29",
  repoName = "WiRe",
  branch = "development",
}

function version.rawBaseUrl()
  return "https://raw.githubusercontent.com/" .. version.repoUser .. "/" .. version.repoName .. "/" .. version.branch .. "/"
end

function version.versionUrl()
  return version.rawBaseUrl() .. "version.txt"
end

function version.trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function version.isDifferent(remoteVersion)
  return version.trim(remoteVersion) ~= version.version
end

return version
