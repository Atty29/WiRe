# WiRe Repository Structure

`server/main.lua` is currently the working server monolith. This is intentional.

The modular files exist so WiRe can be split safely later without breaking existing devices.

## Rule

Do not change the working discovery, encryption, server colour or device registration code unless creating a planned breaking protocol version.
