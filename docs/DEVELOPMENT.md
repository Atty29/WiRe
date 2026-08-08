# WiRe Development Guide

This document records the working rules for changing WiRe without unnecessarily destabilising existing installations.

## Primary rule

**Keep working WiRe installations working.**

WiRe contains a substantial amount of proven legacy ComputerCraft code alongside newer features. Improvements should normally be small, understandable and testable.

## Before changing working code

1. Identify which program(s) use the behaviour being changed.
2. Check whether the change affects network packets, encryption, saved data, device states or installer paths.
3. Preserve compatibility unless a breaking change is intentional and documented.
4. Make one logical change at a time.
5. Commit working milestones frequently so regressions are easy to isolate and revert.
6. Test the affected Server/Client/Trigger/Sensor combination in CC:Tweaked before treating the change as complete.

## Areas requiring extra care

The following are compatibility-sensitive:

- Rednet discovery and hosting
- Network names derived from server colour
- Packet fields and `program` identifiers
- Computer-ID validation
- AES/base64 communication code
- Communication-key construction
- Device state names (`OPEN`, `CLOSED`, `ON`, `OFF`, etc.)
- Lock/unlock commands
- Runtime configuration paths
- Group save/migration format
- Installer destination paths

Do not refactor these solely for appearance.

## Current architecture

The main programs are still largely self-contained:

- Server
- Client
- Trigger
- Sensor
- Tablet

The `shared/` directory represents the direction of future development, but some modules are placeholders. Code should only be moved there when both callers can be updated and tested together.

## Runtime data

Program updates should not overwrite user-created data.

Server groups currently live at:

```text
/data/WiRe/groups
```

Backups live under:

```text
/data/WiRe/backups/
```

The server also understands the legacy `/data/WiReGroups` location and migrates it.

The main server configuration is stored at `/data/WiReServerCfg`.

## Known technical debt

### Version consolidation

Several version concepts currently coexist. The working server has its own version string while repository/package metadata has separate development version values.

Future work should establish one authoritative version source and make the installer/updater/programs consume it where practical.

### Installer and manifest consolidation

`installer/install.lua` currently contains its own package definitions. `manifest.lua` separately describes a more complete package layout.

Future work should make one definition authoritative. Do not change the existing installer paths casually because users may already have installations using them.

### Shared modules

`shared/protocol.lua` and `shared/crypto.lua` are currently scaffolding. The proven communication implementation remains embedded in the working programs.

Extraction should happen incrementally, with compatibility testing after each step.

### Network authentication

Current encryption keys are derived from ComputerCraft IDs and a fixed WiRe string. This provides obfuscation/encryption but not a strong shared-secret authentication model.

A future protocol revision should consider a generated network/team secret or pairing mechanism. This should be designed as a compatibility-aware change rather than patched into only one program.

### Large source files

The working programs, especially the Server, are large. Splitting them into modules is desirable eventually, but functionality should be extracted by subsystem rather than through a wholesale rewrite.

## Documentation rules

When a feature becomes part of the working `main` branch:

- Update `README.md` if it changes user-visible capabilities or installation.
- Update `docs/STRUCTURE.md` if files, directories or runtime paths change.
- Update this document when a new compatibility constraint or major technical-debt item is discovered.

## Formatting

For new Lua code:

- Use consistent indentation within the surrounding section.
- Keep comments concise and useful.
- Prefer descriptive local names.
- Avoid introducing globals unless the existing architecture requires them.
- Keep related helpers together where practical.
- Do not perform formatting-only rewrites of entire legacy files unless there is a specific reason; large whitespace diffs make functional changes harder to review.

## Commits

Prefer focused commits such as:

```text
fix: preserve group state during refresh
feat: add trigger server-info request
docs: document runtime data layout
refactor: extract shared colour definitions
```

A commit should ideally leave WiRe in a runnable state.

## Licensing and credits

The original WiRe project was created by Dog / HydrantHunter. Preserve the original credits in derived/legacy source files.

The repository's current `LICENSE` notice is not a standard open-source licence. Do not replace it with another licence until the permissions applying to the original WiRe source have been established.
