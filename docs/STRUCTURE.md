# WiRe Rewired Repository Structure

WiRe Rewired is being modularised **around the proven WiRe programs first**. The large working Server/Client/Trigger/Sensor/Tablet files remain intact while new cross-cutting behaviour is moved into smaller runtime/shared modules that can be tested independently.

## Working behaviour layer

| Path | Purpose |
| --- | --- |
| `server/main.lua` | Central WiRe server, monitor UI, device management, groups and security controls. |
| `client/main.lua` | Standard WiRe redstone device client. |
| `trigger/main.lua` | Remote/automatic control interface for groups and devices. |
| `sensor/main.lua` | Sensor-side WiRe functionality. |
| `tablet/main.lua` | Tablet development client. |

These files remain the compatibility layer. Their size is known technical debt, not a reason to perform an all-at-once rewrite.

## Runtime layer

`runtime/launcher.lua` runs in front of the working program on the development build.

It currently provides:

- development-build identification;
- component selection;
- team setup;
- team network namespace mapping;
- update notification;
- restoration of normal Rednet functions when the component exits.

### Team namespace model

Existing WiRe programs continue to use familiar protocols such as `WiRePurple`. When team isolation is enabled, the development launcher remaps that protocol at the Rednet boundary to a team-scoped form such as:

```text
WiReRewired:ALPHA:WiRePurple
```

The working WiRe programs do not need to know about the remapping. Each team can therefore reuse the normal 16 ComputerCraft colour slots independently.

This is **network isolation**, not strong cryptographic authentication. Authentication remains future protocol work.

## Shared modules

| Path | Status / purpose |
| --- | --- |
| `shared/version.lua` | Active development package/version metadata and remote-version URL helper. |
| `shared/team.lua` | Active team configuration and protocol namespace helper. |
| `shared/protocol.lua` | Common metadata/names for new code; legacy packet implementation is not yet extracted. |
| `shared/storage.lua` | Generic table save/load helper for new modular code. |
| `shared/colours.lua` | Shared colour definitions/scaffolding. |
| `shared/ui.lua` | Shared UI scaffolding. |
| `shared/crypto.lua` | Placeholder only; working AES remains in the proven programs. |

Do not assume a shared module replaces legacy behaviour merely because it exists.

## Installer and package layout

### Stable/current path

`installer/install.lua` remains the existing `main`-branch installer and is deliberately not being changed by development work.

### Development path

`installer/install-dev.lua` is the manifest-driven development installer.

On the `development` branch, `manifest.lua` is the authoritative package file list. It defines common runtime/shared tools and component-specific files for Server, Client, Trigger, Sensor, Tablet and Full Package installs.

Development installations use a consistent flat component layout:

```text
wire/server.lua
wire/client.lua
wire/trigger.lua
wire/sensor.lua
wire/tablet.lua
wire/runtime/launcher.lua
wire/shared/...
wire/tools/...
wire/component.cfg
wire/version.txt
```

`wire/component.cfg` records the component selected by the installer. Runtime configuration remains under `/data`.

## Tools

| Path | Purpose |
| --- | --- |
| `tools/update.lua` | Component-aware development updater. |
| `tools/team.lua` | View/change the team or switch to legacy networking. |
| `tools/selftest.lua` | Non-destructive installed-file/module sanity check. |

## Documentation

- `README.md` — project/development-build overview.
- `docs/STRUCTURE.md` — architecture and repository boundaries.
- `docs/DEVELOPMENT.md` — rules, compatibility constraints and technical debt.
- `docs/TESTING.md` — Minecraft/CC:Tweaked regression and feature test plan.

## Legacy material

The `legacy/` directory preserves earlier source/reference material. Keep it while compatibility with older WiRe behaviour remains important.

## Runtime data

WiRe user configuration is intentionally separate from downloaded program files.

Current important paths include:

```text
/data/WiReServerCfg
/data/WiReClientCfg
/data/WiRe/groups
/data/WiRe/backups/
/data/WiRe/team.cfg
```

Older `/data/WiReGroups` group data is migrated by the Server and a legacy backup is retained.

The development installer/updater does not remove `/data` configuration.

## Compatibility rule

Do not casually change the working:

- discovery format;
- encryption/decryption behaviour;
- key construction;
- packet fields and program identifiers;
- device registration behaviour;
- command/state names;
- saved-data formats.

Changes in those areas should be planned and tested as protocol/data-migration work.

## Refactoring rule

Prefer small extractions with a clear test path over a large rewrite. A duplicated piece of proven legacy code is preferable to a cleaner abstraction that makes existing WiRe installations stop communicating.
