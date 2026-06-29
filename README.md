# WiRe

WiRe = Wireless Redstone control for ComputerCraft / CC:Tweaked.

This repository is the new modular home for WiRe. The current working server is kept as `server/main.lua` so existing clients/devices keep using the known working discovery, encryption, setup and registration flow.

## Install

Once this repo is uploaded to GitHub under:

```text
https://github.com/Atty29/WiRe
```

ComputerCraft users can install using the installer file from Pastebin, or directly with:

```lua
wget run https://raw.githubusercontent.com/Atty29/WiRe/main/installer/install.lua
```

## Current packages

- `server` - working WiRe Server+ monolith from the current stable file.
- `client` - placeholder for future client package.
- `trigger` - placeholder for future WiRe Trigger package.
- `tablet` - placeholder for future tablet package.
- `shared` - shared libraries for future modular WiRe.

## Important

Do not rewrite the working server network layer unless you are intentionally making a breaking protocol update. Existing devices depend on the old discovery/encryption/registration path.

## Roadmap

- v2.1: search/sort/header UI patch to the working server.
- v2.2: optional PIN lock and panic lock security layer.
- v2.3: tablet remote access.
- v3.0: proper modular server split after the monolith is safely mapped.
