# WiRe

**WiRe (Wireless Redstone)** is a wireless device-management and automation system for **ComputerCraft / CC:Tweaked**.

WiRe allows players to discover, register, organise and control wireless redstone devices from a central server. Devices can be controlled manually, arranged into reusable groups, or operated automatically through WiRe Trigger.

WiRe is intentionally generic. It can control anything operated by a redstone signal, including:

- Doors and hatches
- Lighting
- Machines and energy devices
- Rail switches
- Farms
- Security systems
- Elevators
- Other redstone-controlled mechanisms

---

## History

The original **WiRe (Wireless Redstone)** project was created by **Dog**, also known as **HydrantHunter**, as a wireless redstone control system for ComputerCraft.

The original project introduced the core idea of discovering wireless redstone devices and controlling them from a central server using wireless modems. The current WiRe Development Project continues from that foundation while expanding the system for modern **CC:Tweaked** installations.

Original WiRe Pastebin: `hqpRw4Jy`

Without Dog's original work, this project would not exist. Original credits are retained in the working source files.

---

## Current Development Edition

The working server currently identifies itself as:

```text
3.0.2 Community Manager
```

WiRe remains under active development. Repository/package versioning is being consolidated and should not yet be treated as a stable public release-number scheme.

### Current capabilities

- WiRe Server and Client
- WiRe Trigger
- WiRe Sensor
- Tablet development client
- Wireless device discovery and registration
- Large device lists with paging
- Device search and A-Z/Z-A sorting
- Device groups and group management
- Saved group configuration with legacy-data migration
- PIN terminal lock
- Panic lock
- Configurable failed-PIN and panic responses
- Trigger access to devices, groups and server information
- GitHub-based installer
- Compatibility with the existing WiRe communication model

---

## Installation

Install from GitHub with:

```text
wget run https://raw.githubusercontent.com/Atty29/WiRe/main/installer/install.lua
```

The current interactive installer offers:

1. WiRe Server
2. WiRe Client
3. WiRe Trigger
4. WiRe Sensor

The tablet and full-package definitions are present in the repository manifest but are not currently exposed by the interactive installer.

---

## Repository Structure

```text
server/       Working WiRe Server
client/       Working WiRe Client
trigger/      WiRe Trigger
sensor/       WiRe Sensor
 tablet/      Tablet development code
shared/       Shared-module scaffolding for future refactoring
installer/    GitHub installer
tools/        Maintenance/update tooling
docs/         Project and development documentation
legacy/       Preserved legacy source/reference material
```

See `docs/STRUCTURE.md` for more detail.

---

## Development Direction

Current development priorities are:

- Keep the working WiRe network stable.
- Preserve compatibility wherever practical.
- Consolidate installer, manifest and version information.
- Improve update/version notification support.
- Continue development of team-aware/server-aware installations.
- Improve network authentication without casually breaking existing devices.
- Move common code into `shared/` gradually and only when it can be tested safely.
- Continue improving documentation and maintainability.

See `docs/DEVELOPMENT.md` for development rules and known technical debt.

---

## Development Philosophy

WiRe follows a few simple principles:

- Keep WiRe generic.
- Preserve compatibility wherever practical.
- Improve through small, tested changes.
- Keep user configuration separate from program files.
- Prefer working code over unnecessary rewrites.
- Build for long-term maintainability.
- Credit the original project and continue its development respectfully.

---

## Licence and Credits

See `LICENSE` for the repository's current notice. The original WiRe credits must remain in the legacy and derived working source files.
