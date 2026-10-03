# K-NAS v0.1

A plug-and-play, Docker-based NAS system. Auto-detects your storage, sets up your media folders, and includes essential apps for a better digital life.

*K-NAS goal is to be a free, easy-to-use, open and minimalistic approach against big techology corporative dependance.*

**Own your things locally! :)**

## Features
- Stream movies, series, music, books, audiobooks and more
- Store photos and videos from all your devices
- Secure VPN
- Ad block
- Automatic backups
- External access via internet
- CCTV storage

More features coming up...


## Prerequisites

- A USB drive (at least 4 GB) to boot the installer
- A machine to use as your NAS (64-bit x86), connected to the internet during the install
- Any computer (Windows, macOS or Linux) to prepare the USB drive

## Start from scratch

Going from an empty machine to a running K-NAS. No Docker, scripts or terminal needed to install.

### 1. Download the K-NAS ISO

Download `debian-auto-installable.iso` from the [latest release](../../releases/latest).

### 2. Write it to a USB drive

Use [balenaEtcher](https://etcher.balena.io) (Windows, macOS, Linux): select the ISO, select your USB drive, and click Flash.

### 3. Install

Boot the NAS machine from the USB drive and wait. The install is unattended and reboots on its own when done.

### 4. Connect to the NAS

From your own computer (Windows, macOS and Linux all include `ssh`), open a terminal and run:

```bash
ssh k-nas-user@<NAS-IP>
```

Replace `<NAS-IP>` with the NAS machine's IP address. You can find it in your router's list of connected devices (look for `k-nas`), or by logging in on the NAS itself and running `ip a`.

Enter the password from the [default credentials](#default-credentials). You will be asked to set a new one right away.

### 5. Set up the machine

Once connected, follow these guides in order:

1. [Static IP](os/debian/NETWORK.md)
2. [Storage](os/debian/STORAGE.md)
3. [Docker](os/debian/DOCKER.md)

## Default credentials

| Setting  | Value        |
|----------|--------------|
| Hostname | `k-nas`      |
| User     | `k-nas-user` |
| Password | `knas`       |

The password is expired at first login, so you must choose a new one the first time you connect. To change these defaults, build your own ISO with an edited `os/debian/preseed.cfg`.
