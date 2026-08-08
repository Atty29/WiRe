# WiRe Rewired Development Test Plan

This checklist is for testing the `development` branch in CC:Tweaked before anything is considered for `main`.

## Safety

Use test computers/devices where practical. The development installer writes program files under `wire/` and may replace `startup.lua` only after asking (except unattended updater runs for an already-installed component).

Existing WiRe runtime configuration under `/data` is not removed by the installer.

## Development install command

```text
wget run https://raw.githubusercontent.com/Atty29/WiRe/development/installer/install-dev.lua
```

The installer clearly identifies itself as the **DEVELOPMENT** installer and offers Server, Client, Trigger, Sensor, Tablet and Full Package installs.

## 1. Basic installation

For each component being tested:

- Confirm every download reports `OK`.
- Confirm `wire/version.txt` contains the development version.
- Confirm `wire/component.cfg` contains the installed component name.
- Run `wire/tools/selftest.lua` and confirm all checks pass.
- Confirm the self-test reports that the shared storage and component-registry modules load.
- If auto-start was selected, reboot and confirm the WiRe Rewired launcher runs.
- Confirm the launcher displays `DEVELOPMENT BUILD` before starting the existing WiRe program.

## 2. Team isolation

Use at least two computers in the same intended team.

On first launcher start:

- Enable team isolation.
- Enter exactly the same team name on the Server and its Clients/Triggers/Sensors/Tablets.
- Configure the normal WiRe colour in the existing program as usual.

Expected result: devices using the same team name and colour communicate normally.

Then configure a second test computer with a different team name but the same WiRe colour.

Expected result: the second team does not discover/control the first team's WiRe server.

Run:

```text
wire/tools/team.lua
```

and confirm the tool can change teams and display the mapped protocol namespace.

### 3.2 storage regression check

The 3.2 development stage moved team configuration onto the shared storage module.

- Note the current team with `wire/tools/team.lua`.
- Reboot the computer.
- Confirm the same team is still selected.
- Change the team, reboot again and confirm the new value persists.

Expected result: `/data/WiRe/team.cfg` behaves exactly as it did in 3.1.

### Legacy compatibility check

Use `wire/tools/team.lua` to disable team isolation on a test device.

Expected result: the launcher stops remapping WiRe protocol names and the program behaves like the existing legacy colour network.

## 3. Server and Client regression test

Confirm the existing behaviour still works through the launcher:

- Server discovers Client.
- Client reports its name/state/location as before.
- OPEN/CLOSED works for door-style clients.
- ON/OFF works for energy-style clients.
- LOCKED/UNLOCK works.
- Auto-close/auto-reactivate works where configured.
- Client offline detection still updates the Server.
- Search and sorting work.
- Device paging works.

## 4. Groups

- Create a group.
- Add multiple device actions.
- Save it.
- Run it.
- Edit it.
- Delete it.
- Reboot the Server and confirm saved groups return.
- If an old `/data/WiReGroups` save is available on a disposable test instance, confirm migration still works.

## 5. Server security

- Enable PIN locking.
- Lock and unlock the terminal.
- Enter three incorrect PINs and confirm the x3 response runs if configured.
- Enter five incorrect PINs and confirm the x5 response runs if configured.
- Test Panic Lock and its configured response.
- Confirm individual actions and saved groups can both be used as security responses.

## 6. Trigger

Confirm Trigger can:

- Find the team/colour Server.
- Request the group list.
- Request the device list.
- Request server information.
- Run a saved group.
- Run multiple groups where supported by the current Trigger UI.
- Send a supported command to a named device.

## 7. Sensor and Tablet

Run the existing Sensor and Tablet builds through the development launcher and verify their current working features are unchanged. Record any UI or peripheral-specific failure rather than attempting to repair it on the live `main` branch.

## 8. Update notification

A normal launch checks `development/version.txt` when HTTP is available.

Expected result when installed and remote versions match: no update warning.

When the development branch version is later increased, an older installation should display an update notice and point to:

```text
wire/tools/update.lua
```

Run the updater and confirm:

- It identifies the currently installed component.
- It re-runs the development installer.
- Program files update.
- New shared modules are downloaded automatically.
- `/data/WiRe/team.cfg` remains intact.
- Existing WiRe Server/Client configuration remains intact.

## 9. Problems to record

For any failure, record:

- Component (Server/Client/Trigger/Sensor/Tablet)
- ComputerCraft computer ID
- Team name
- WiRe colour
- Whether the modem is wireless or wired
- Monitor layout/size where relevant
- Exact on-screen error
- What action caused it

Do not merge `development` into `main` until the core Server/Client/Trigger paths pass real in-game testing.
