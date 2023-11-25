# OpenWRT Configuration Management

This is more documentation than automation, but it's been serving me well
enough that I haven't been motivated to automate much further.

## Overview

You can skip to [Installation and Setup](#installation-and-setup) if you
like.

### Motivation

My requirements, which got me to this point, are:

1. Manage multiple OpenWRT devices as similarly and easily as possible.
2. Maintain history, the ability to revert changes, and visibility into any
   changes.
3. Depend as little as possible on packages installed on devices.
4. A path to further automation.

### Basic Approach

The basic idea is to edit device configuration on a \*nix (Linux, in my
case) box via [sshfs](https://github.com/libfuse/sshfs) and maintain that
configuration in git hosted on the \*nix box.

### Prerequisites

1. You need a \*nix box of some sort with sshfs, GNU make, and git
   installed. On Debian-derived Linux distributions, including Ubuntu,
   that's as simple as `sudo apt-get install sshfs git make` and it's done.
   Other distributions or \*nix systems will vary.
2. You need the `openssh-sftp-server` package installed on all of your
   OpenWRT devices; I recommend using the [Firmware
   Selector](https://firmware-selector.openwrt.org/) to build a custom
   image with the package included in it.
3. You don't strictly _need_ an [ssh authorized
   key](https://openwrt.org/docs/guide-user/security/dropbear.public-key.auth)
   on your OpenWRT devices, but I strongly recommend it; this is something
   of a pain without it.
4. To use the [`latest_firmware`](SCRIPTS/latest_firmware) script, you need
   `jq` and `curl` installed on your \*nix box.

## Installation and Setup

Once you've satisfied the [prerequisites](#prerequisites) above, nothing
further has to be done on the device side. 

