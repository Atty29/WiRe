# WiRe Rewired

**WiRe Rewired** is the current development continuation of **WiRe (Wireless Redstone)** for **ComputerCraft / CC:Tweaked**.

It is a generic wireless device-management and automation platform: discover devices, organise them, control them from a central Server, run saved groups, trigger automation remotely and build larger systems without tying WiRe to one specific Minecraft mod or machine type.

Typical uses include doors and hatches, lighting, machines, energy systems, rail switches, farms, security systems, elevators and any other redstone-controlled mechanism.

---

## History

The original **WiRe (Wireless Redstone)** project was created by **Dog**, also known as **HydrantHunter**.

The original project introduced the core idea of discovering wireless redstone devices and controlling them from a central ComputerCraft server using wireless modems. WiRe Rewired continues from that foundation while expanding it for modern **CC:Tweaked** installations.

Original WiRe Pastebin: `hqpRw4Jy`

Without Dog's original work, this project would not exist. Original credits are retained in the working and legacy source files.

---

## Development Build

Current development package version:

```text
3.1.0-dev
```

The working legacy-derived Server still contains its own internal historical version label. Package/version consolidation is intentionally being handled around the proven programs first rather than by making risky cosmetic edits to the large working files.

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
- **Team network isolation** while preserving the existing WiRe programs
- **Up to 16 colour-server slots per team**
- Development-build launcher
- In-game update notification at launch
- Manifest-driven development installer
- Component-aware updater
- Compatibility mode for existing non-team WiRe networks

---

## Install the Development Build

```text
wget run https://raw.githubusercontent.com/Atty29/WiRe/development/installer/install-dev.lua
```

The development installer offers:

1. WiRe Rewired Server
2. WiRe Rewired Client
3. WiRe Rewired Trigger
4. WiRe Rewired Sensor
5. WiRe Rewired Tablet
6. Full development package

The installer downloads its file list from `manifest.lua`, so package definitions now have one authoritative source on the development branch.

### Team setup

The development launcher asks for a team on first run. Use the **same team name** on a Server and all Clients/Triggers/Sensors/Tablets intended to communicate with it.

Each team receives its own WiRe network namespace while the established programs continue to use their normal colour model internally. This means the usual ComputerCraft colours can be reused independently by different teams — effectively **16 WiRe colour-server slots per team**.

To change the team later:

```text
wire/tools/team.lua
```

Legacy non-team networking can also be selected from that tool.

### Updates

The launcher compares the installed development version with the current `development/version.txt` when HTTP is available. If a newer/different development build is detected, it displays an update notice without automatically changing the installation.

Update manually with:

```text
wire/tools/update.lua
```

WiRe configuration stored under `/data` is kept separate from downloaded program files.

---

## Repository Structure

```text
server/       Working WiRe Server
client/       Working WiRe Client
trigger/      WiRe Trigger
sensor/       WiRe Sensor
tablet/       Tablet development code
runtime/      Development launcher/runtime compatibility layer
shared/       Shared helpers and modularisation targets
installer/    Main and development installers
tools/        Update/team/maintenance tools
docs/         Project, development and testing documentation
legacy/       Preserved legacy source/reference material
```

See `docs/STRUCTURE.md` for repository boundaries and `docs/TESTING.md` for the Minecraft test plan.

---

## Development Approach

The current large Server/Client/etc. files remain the proven behaviour layer. WiRe Rewired is being subdivided **around them first** rather than performing a risky all-at-once rewrite.

The development runtime now owns cross-cutting behaviour such as team namespaces, build identification and update notification. Shared modules provide clean homes for new common functionality. Existing packet/encryption code stays in place until it can be extracted and tested safely.

Current priorities are:

- Keep existing Server/Client/Trigger behaviour working.
- Test team isolation in a real multiplayer CC:Tweaked environment.
- Keep configuration outside downloaded program files.
- Continue moving suitable common functionality into `shared/` in small tested stages.
- Improve authentication in a future compatibility-aware protocol revision.
- Keep `main` stable while development work is tested on the `development` branch.

---

## Development Philosophy

- Keep WiRe generic.
- Preserve compatibility wherever practical.
- Improve through small, tested changes.
- Keep user configuration separate from program files.
- Prefer working code over unnecessary rewrites.
- Commit useful milestones frequently.
- Build for long-term maintainability.
- Credit the original project and continue its development respectfully.

---

## Licence and Credits

See `LICENSE` for the repository's current notice. The original WiRe credits must remain in the legacy and derived working source files.
