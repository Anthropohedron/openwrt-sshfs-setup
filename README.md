# OpenWRT Configuration Management

This is more documentation than automation, but it's been serving me well enough that I haven't been motivated to automate much further.

## Overview

You can skip to [Installation and Setup](#installation-and-setup) if you like.

### Motivation

My requirements, which got me to this point, are:

1. Manage multiple OpenWRT devices as similarly and easily as possible.
2. Maintain history, the ability to revert changes, and visibility into any changes.
3. Depend as little as possible on packages installed on devices.
4. A path to further automation.

### Basic Approach

The basic idea is to edit device configuration on a \*nix (Linux, in my case) box via [sshfs](https://github.com/libfuse/sshfs) and maintain that configuration in git hosted on the \*nix box.

### Prerequisites

1. You need a \*nix box of some sort with sshfs, GNU make, and git installed. On Debian-derived Linux distributions, including Ubuntu, that's as simple as `sudo apt-get install sshfs git make` and it's done. Other distributions or \*nix systems will vary.
2. You need the `openssh-sftp-server` package installed on all of your OpenWRT devices; I recommend using the [Firmware Selector](https://firmware-selector.openwrt.org/) to build a custom image with the package included in it.
3. You don't strictly _need_ an [ssh authorized key](https://openwrt.org/docs/guide-user/security/dropbear.public-key.auth) on your OpenWRT devices, but I strongly recommend it; this is something of a pain without it.
4. To use the [`latest_firmware`](SCRIPTS/latest_firmware) script, you need `jq` and `curl` installed on your \*nix box.

If you use vim, I highly recommend the [vim-uci](https://github.com/cmcaine/vim-uci) plugin to get syntax highlighting for the config files. Note that you will need to inform vim that the `filetype` is `uci`, either with a modeline or an autocommand.

## Installation and Setup

Once you've satisfied the [prerequisites](#prerequisites) above, nothing further has to be done on the device side. Everything below is to be done on the \*nix box. You should be prepared to edit your `/etc/fstab`, which almost certainly requires `sudo`.

The first step is to clone this repo locally, possibly after forking it into your own GitHub account. Go into the directory in your shell and run `make new` (which will run the [`new_device`](SCRIPTS/new_device) script). You will be prompted to provide the name of the device and, optionally, its IP address. You will then be prompted to add a line to your `/etc/fstab` for mounting via sshfs. Finally, it will create some directories and commit the contents of the `/etc/config` directory on the device to a local git repo.

Let's go through an example, with a device cleverly named `router` with a LAN IP address of `192.168.1.1`:

```
[~/openwrt-sshfs-setup]% make new
Enter the new device name: router
Enter the device IP address or its resolvable hostname: 192.168.1.1
The following line can be added to /etc/hosts to make things more convenient:

192.168.1.1	router

It can be added with the following command, which may prompt for sudo
credentials:

printf '%s\t%s\n' "192.168.1.1" "router" | sudo tee -a /etc/hosts >/dev/null

Would you like to do so? [Yn] Y
[sudo] password for XXXXX:
The following line must be added to your /etc/fstab:

root@router:/etc/config /home/XXXXX/openwrt-sshfs-setup/router sshfs defaults,user,uid=1000,gid=1000 0 0

It can be added with the following command, which may prompt for sudo
credentials:

printf 'root@%s:/etc/config %s/%s sshfs defaults,user,%s 0 0\n' \
	"router" "/home/XXXXX/openwrt-sshfs-setup" "router" "uid=1000,gid=1000" | sudo tee -a /etc/fstab >/dev/null

Would you like to do so? If not, please add it manually now. [Yn] Y
[main (root-commit) d3c9138] initial commit
...
[~/openwrt-sshfs-setup]%
```

At this point several things will have happened:
1. If it didn't already exist, the directory `GIT` will have been created.
2. The directory `router` will have been created.
3. The `/etc/config` directory on the device will be mounted on the `router` directory.
4. There will be a symlink in that mounted directory to the `.git` directory for the router.
5. The contents of the mounted directory will be committed to the git repo.
6. There is an entry in `/etc/fstab` which will allow future mounting without requiring `sudo`.
7. There is an entry in `/etc/hosts` to let you resolve the device's name to its IP address (e.g. for ssh).

You may also want to add (something like) the following to your `~/.ssh/config` for ssh convenience:

```sshconfig
Host router
Tunnel no
ForwardAgent no
ForwardX11 no
Port 22
User root
```

## Operation

When a device's `/etc/config` directory is mounted, it is then possible to edit the device configuration from the mounting \*nix box. Remember to ssh to the device to load configuration changes, e.g. `ssh router service firewall reload`, and remember to commit frequently.

### Mounting

You can mount all known devices with `make mount`.

### Unmounting

You can unmount all known devices with `make umount`.

### Adding Another Device

Running `make new` will walk you through adding a new device.

### Checking Firmware Version

You can get the devices' OpenWRT version number via ssh with `make versions`.

## Advanced

If you, like me, prefer to build a custom firmware image (e.g. to include some extra packages and possibly remove some you don't need), the [`latest_firmware`](SCRIPTS/latest_firmware) script will be helpful. It takes a JSON file which conforms to the [`BuildRequest` schema](https://sysupgrade.openwrt.org/ui/#/model-BuildRequest) and produces an URL to download a sysupgrade firmware image suitable for installing with `sysupgrade -c -u`. The script supplies a few default values for the build request, including:

- diff_packages: `false`, which means that any packages given are _in addition to_ the default for the device
- client: `"curl"`
- version: The default (latest) version according to the [Firmware Selector](https://firmware-selector.openwrt.org/)

Any of these fields can be overridden in the supplied JSON file. I recommend keeping a `firmware.json` file for the purpose in devices' `/etc/config` (and therefore in their git repos).

Note that you _must_ supply values for the `profile` and `target` fields, at a minimum. The `profile` value can be found in the device's `/etc/board.json` file in the `.model.id` field, replacing any comma `,` (there is probably a comma) with an underscore `_`. The `target` value can be found in the device's `/etc/openwrt_release` file as the value of `DISTRIB_TARGET`.

