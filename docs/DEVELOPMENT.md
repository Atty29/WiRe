# WiRe Rewired Development Guide

This document records the working rules for changing WiRe Rewired without unnecessarily destabilising existing installations.

## Primary rule

**Keep working WiRe installations working.**

WiRe contains a substantial amount of proven legacy ComputerCraft code alongside newer features. Improvements should normally be small, understandable and testable.

## Branch policy

- `main` is the stable/current branch and should remain untouched by untested development work.
- `development` is the integration/testing branch for WiRe Rewired changes.
- Feature/refactor branches may be used for higher-risk work before it reaches `development`.
- Do not merge `development` into `main` until core behaviour has been tested in Minecraft/CC:Tweaked.

## Before changing working code

1. Identify which program(s) use the behaviour being changed.
2. Check whether the change affects network packets, encryption, saved data, device states or installer paths.
3. Preserve compatibility unless a breaking change is intentional and documented.
4. Make one logical change at a time.
5. Commit working milestones frequently so regressions are easy to isolate and revert.
6. Test the affected Server/Client/Trigger/Sensor/Tablet combination in CC:Tweaked before treating the change as complete.

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

Do not refactor these solely for appearance.

## Development architecture

The main Server/Client/Trigger/Sensor/Tablet programs remain the proven behaviour layer.

The `development` branch adds a runtime layer in front of them rather than immediately rewriting their internals.

### Runtime responsibilities

`runtime/launcher.lua` currently owns:

- development-build identification;
- component selection;
- team configuration;
- team-scoped Rednet protocol mapping;
- launch-time update notification.

This lets WiRe gain new cross-cutting behaviour without rewriting the established encrypted packet handling inside every component at once.

### Team model

Teams were chosen instead of per-player WiRe allocations.

Each team can independently reuse the normal ComputerCraft colour networks. Because WiRe already uses colour as its server/network grouping model, that naturally provides up to **16 colour-server slots per team**.

The runtime maps a legacy protocol such as:

```text
WiRePurple
```

to a team-scoped protocol such as:

```text
WiReRewired:TEAM-NAME:WiRePurple
```

when team isolation is enabled.

Legacy mode leaves the original protocol untouched.

This currently prevents accidental cross-team discovery/control. It is not a substitute for strong cryptographic authentication.

## Runtime data

Program updates should not overwrite user-created data.

Important paths include:

```text
/data/WiReServerCfg
/data/WiReClientCfg
/data/WiRe/groups
/data/WiRe/backups/
/data/WiRe/team.cfg
```

The Server also understands the legacy `/data/WiReGroups` location and migrates it.

## Development installer and updater

`manifest.lua` is the authoritative package definition for the `development` branch.

`installer/install-dev.lua` reads that manifest and installs the selected package plus common runtime/shared files.

`tools/update.lua` re-runs the development installer for the recorded component. It must preserve `/data` configuration and must not take over a custom `startup.lua` that was not created by the development installer.

## Known technical debt

### Internal program version labels

The development package now has a consistent external version (`version.txt`, `shared/version.lua`, `manifest.lua`), but the large legacy-derived programs still contain their own historical internal version strings.

Do not edit those files solely to make the labels match. Consolidate internal version display when each program is already being safely touched/tested.

### Shared crypto/protocol extraction

`shared/protocol.lua` now records common names/metadata for new development code. `shared/crypto.lua` remains intentionally inactive.

The proven packet/encryption implementation still lives inside the working programs. Extraction should happen incrementally, with compatibility testing after each step.

### Network authentication

Current WiRe encryption keys are derived from ComputerCraft IDs and a fixed WiRe string. Team namespace isolation does not change that fact.

A future compatibility-aware protocol revision should add a genuine shared secret/pairing/authentication mechanism. Do not claim the current team namespace is cryptographic security.

### Large source files

The working programs, especially the Server, are large. Splitting them into modules is desirable eventually, but functionality should be extracted by subsystem rather than through a wholesale rewrite.

### Existing-file cleanup

Some legacy-derived source files contain old formatting, duplicate comments or historical leftovers. Remove those when the file is already being changed and tested for a functional reason, rather than generating giant formatting-only diffs.

## Update notification rule

The development launcher may check the remote development version and **notify** the user when it differs. It must not silently replace working code at launch.

The user explicitly chooses when to run `wire/tools/update.lua`.

## Documentation rules

When development behaviour changes:

- Update `README.md` for user-visible capabilities or installation changes.
- Update `docs/STRUCTURE.md` for files, modules, architecture or runtime paths.
- Update `docs/TESTING.md` when a new feature needs a regression test.
- Update this document when a new compatibility constraint or major technical-debt item is discovered.

## Formatting

For new Lua code:

- Use consistent two-space indentation in new modular files.
- Keep comments concise and useful.
- Prefer descriptive local names.
- Avoid introducing globals unless the existing architecture requires them.
- Keep related helpers together where practical.
- Do not perform formatting-only rewrites of entire legacy files unless there is a specific reason.

## Commits

Prefer focused commits such as:

```text
fix: preserve group state during refresh
feat: add team namespace runtime
feat: add launch-time update notice
docs: add Minecraft development test plan
refactor: extract shared colour definitions
```

A commit should ideally leave the branch in a runnable state.

## Licensing and credits

The original WiRe project was created by Dog / HydrantHunter. Preserve the original credits in derived/legacy source files.

The repository's current `LICENSE` notice is not a standard open-source licence. Do not replace it with another licence until the permissions applying to the original WiRe source have been established.
