-- WiRe download manifest
-- The installer reads this file from GitHub raw and downloads the package selected by the user.

return {
  name = "WiRe",
  version = "2.0.0-repo-start",
  baseUrl = "https://raw.githubusercontent.com/Atty29/WiRe/main/",

  packages = {
    server = {
      label = "WiRe Server",
      startup = "wire/server/main.lua",
      files = {
        { src = "server/main.lua", dest = "wire/server/main.lua" },
        { src = "version.txt", dest = "wire/version.txt" },
        { src = "README.md", dest = "wire/README.md" },
      }
    },

    client = {
      label = "WiRe Client",
      startup = "wire/client/main.lua",
      files = {
        { src = "client/main.lua", dest = "wire/client/main.lua" },
        { src = "shared/protocol.lua", dest = "wire/shared/protocol.lua" },
        { src = "shared/crypto.lua", dest = "wire/shared/crypto.lua" },
        { src = "version.txt", dest = "wire/version.txt" },
      }
    },

    trigger = {
      label = "WiRe Trigger",
      startup = "wire/trigger/main.lua",
      files = {
        { src = "trigger/main.lua", dest = "wire/trigger/main.lua" },
        { src = "shared/protocol.lua", dest = "wire/shared/protocol.lua" },
        { src = "shared/crypto.lua", dest = "wire/shared/crypto.lua" },
        { src = "version.txt", dest = "wire/version.txt" },
      }
    },

    tablet = {
      label = "WiRe Tablet",
      startup = "wire/tablet/main.lua",
      files = {
        { src = "tablet/main.lua", dest = "wire/tablet/main.lua" },
        { src = "shared/protocol.lua", dest = "wire/shared/protocol.lua" },
        { src = "shared/crypto.lua", dest = "wire/shared/crypto.lua" },
        { src = "shared/ui.lua", dest = "wire/shared/ui.lua" },
        { src = "version.txt", dest = "wire/version.txt" },
      }
    },

    full = {
      label = "Full WiRe Package",
      startup = nil,
      files = {
        { src = "server/main.lua", dest = "wire/server/main.lua" },
        { src = "client/main.lua", dest = "wire/client/main.lua" },
        { src = "trigger/main.lua", dest = "wire/trigger/main.lua" },
        { src = "tablet/main.lua", dest = "wire/tablet/main.lua" },
        { src = "shared/protocol.lua", dest = "wire/shared/protocol.lua" },
        { src = "shared/crypto.lua", dest = "wire/shared/crypto.lua" },
        { src = "shared/colours.lua", dest = "wire/shared/colours.lua" },
        { src = "shared/storage.lua", dest = "wire/shared/storage.lua" },
        { src = "shared/ui.lua", dest = "wire/shared/ui.lua" },
        { src = "tools/update.lua", dest = "wire/tools/update.lua" },
        { src = "version.txt", dest = "wire/version.txt" },
        { src = "README.md", dest = "wire/README.md" },
      }
    }
  }
}
