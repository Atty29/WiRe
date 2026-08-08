# WiRe Repository Structure

WiRe is in a transitional state between its original monolithic programs and a future modular layout. The large working programs are intentionally being kept intact until individual systems can be moved safely and tested.

## Working programs

| Path | Purpose |
| --- | --- |
| `server/main.lua` | Central WiRe server, monitor UI, device management, groups and security controls. |
| `client/main.lua` | Standard WiRe redstone device client. |
| `trigger/main.lua` | Remote/automatic control interface for groups and devices. |
| `sensor/main.lua` | Sensor-side WiRe functionality. |
| `tablet/main.lua` | Tablet development client. |

These files are the working implementations. Their size is known technical debt, not an invitation to perform a large rewrite.

## Shared modules

The `shared/` directory is the intended home for reusable code such as protocol definitions, cryptography helpers, storage helpers, colours and UI functions.

Some shared modules are currently scaffolding only. Working protocol/encryption logic remains inside the established programs until it can be extracted without breaking compatibility.

**Do not assume a shared module is active simply because it exists.**

## Installer and package information

- `installer/install.lua` is the current user-facing interactive installer.
- `manifest.lua` describes the intended package/file layout and includes definitions not yet exposed by the interactive installer.
- `version.txt` contains repository-level version information.
- `tools/` contains maintenance/update-related tooling.

The installer, manifest and program version strings are not yet fully consolidated. This is documented technical debt and should be fixed deliberately rather than by changing paths casually.

## Documentation

- `README.md` gives the public project overview and current capabilities.
- `docs/STRUCTURE.md` describes repository layout and boundaries.
- `docs/DEVELOPMENT.md` records development rules and known cleanup work.

## Legacy material

The `legacy/` directory preserves earlier source/reference material. It should remain available while compatibility with older WiRe behaviour is still important.

## Runtime data

WiRe keeps user-generated configuration separate from the program source wherever practical.

Current server group data uses:

```text
/data/WiRe/groups
/data/WiRe/backups/
```

Older `/data/WiReGroups` group data is migrated by the server and a legacy backup is retained.

The main server configuration remains at:

```text
/data/WiReServerCfg
```

Keeping runtime data outside the installed program files reduces the risk of an update destroying a user's configuration.

## Compatibility rule

Do not casually change the working:

- discovery format;
- encryption/decryption behaviour;
- key construction;
- server colour/network behaviour;
- device registration packets;
- command/state names;
- installer paths;
- saved-data formats.

Changes to those areas should be planned, tested and treated as protocol/data-migration work where appropriate.

## Refactoring rule

Prefer small extractions with a clear test path over a large rewrite. A duplicated piece of proven legacy code is preferable to a cleaner abstraction that makes existing WiRe devices stop communicating.
