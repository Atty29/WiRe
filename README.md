# WiRe

**WiRe (Wireless Redstone)** is a wireless device management and automation system for **ComputerCraft / CC:Tweaked**.

WiRe allows players to discover, register and control wireless redstone devices from one or more central servers. Devices can be organised into groups, controlled manually through WiRe Client or automatically through WiRe Trigger.

WiRe is designed to be completely generic. It can control anything that can be operated by a redstone signal, including (but not limited to):

- Doors
- Lighting
- Machines
- Rail switches
- Farms
- Security systems
- Elevators
- Any other redstone-controlled mechanism

---

## Original Project

The original **WiRe** project was created by **Dog (HydrantHunter)**.

This repository is the **WiRe Development Project**, which continues development while preserving credit to the original author.

---

# Installation

Install the latest development version directly from GitHub:

```text
wget run https://raw.githubusercontent.com/Atty29/WiRe/main/installer/install.lua
```

The installer currently supports:

- WiRe Server
- WiRe Client
- WiRe Trigger

Tablet support will be added in a future release.

---

# Current Repository Structure

```
server/
    WiRe Server

client/
    WiRe Client

trigger/
    WiRe Trigger

shared/
    Shared libraries

installer/
    GitHub installer

docs/
    Project documentation
```

---

# Development Status

Current Version

```
0.1.0-dev
```

Current Features

- GitHub installer
- WiRe Server
- WiRe Client
- WiRe Trigger
- Existing WiRe compatibility

---

# Roadmap

## v0.2

- Search
- Device Sorting
- Updated Server Interface

## v0.3

- Security System
- PIN Lock
- Panic Lock

## v0.4

- Tablet Support

## v1.0

- First Stable Release

---

# Development Philosophy

The WiRe Development Project follows a few simple principles:

- Keep WiRe generic.
- Preserve compatibility wherever practical.
- Improve through small, tested changes.
- Build for long-term maintainability.
- Credit the original project and continue its development respectfully.
