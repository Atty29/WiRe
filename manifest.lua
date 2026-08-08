-- WiRe Rewired development download manifest
-- This file is the authoritative package definition for the development branch.

return {
  name = "WiRe Rewired",
  version = "3.1.0-dev",
  channel = "development",
  branch = "development",
  baseUrl = "https://raw.githubusercontent.com/Atty29/WiRe/development/",

  common = {
    { src = "runtime/launcher.lua", dest = "wire/runtime/launcher.lua" },
    { src = "shared/version.lua", dest = "wire/shared/version.lua" },
    { src = "shared/team.lua", dest = "wire/shared/team.lua" },
    { src = "shared/protocol.lua", dest = "wire/shared/protocol.lua" },
    { src = "shared/crypto.lua", dest = "wire/shared/crypto.lua" },
    { src = "shared/colours.lua", dest = "wire/shared/colours.lua" },
    { src = "shared/storage.lua", dest = "wire/shared/storage.lua" },
    { src = "shared/ui.lua", dest = "wire/shared/ui.lua" },
    { src = "tools/update.lua", dest = "wire/tools/update.lua" },
    { src = "tools/team.lua", dest = "wire/tools/team.lua" },
    { src = "tools/selftest.lua", dest = "wire/tools/selftest.lua" },
    { src = "version.txt", dest = "wire/version.txt" },
    { src = "README.md", dest = "wire/README.md" },
    { src = "docs/TESTING.md", dest = "wire/TESTING.md" },
  },

  packages = {
    server = {
      label = "WiRe Rewired Server",
      component = "server",
      files = {
        { src = "server/main.lua", dest = "wire/server.lua" },
      },
    },

    client = {
      label = "WiRe Rewired Client",
      component = "client",
      files = {
        { src = "client/main.lua", dest = "wire/client.lua" },
      },
    },

    trigger = {
      label = "WiRe Rewired Trigger",
      component = "trigger",
      files = {
        { src = "trigger/main.lua", dest = "wire/trigger.lua" },
      },
    },

    sensor = {
      label = "WiRe Rewired Sensor",
      component = "sensor",
      files = {
        { src = "sensor/main.lua", dest = "wire/sensor.lua" },
      },
    },

    tablet = {
      label = "WiRe Rewired Tablet",
      component = "tablet",
      files = {
        { src = "tablet/main.lua", dest = "wire/tablet.lua" },
      },
    },

    full = {
      label = "Full WiRe Rewired Development Package",
      component = nil,
      files = {
        { src = "server/main.lua", dest = "wire/server.lua" },
        { src = "client/main.lua", dest = "wire/client.lua" },
        { src = "trigger/main.lua", dest = "wire/trigger.lua" },
        { src = "sensor/main.lua", dest = "wire/sensor.lua" },
        { src = "tablet/main.lua", dest = "wire/tablet.lua" },
      },
    },
  },
}
