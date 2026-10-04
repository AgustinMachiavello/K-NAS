# K-NAS v0.1

Debian 13 plus Docker apps for your NAS. No hassle.

*K-NAS is a simple first step away from big tech dependence.*

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
- A machine to use as your NAS (64-bit x86), connected to the internet during the install and the first start
- Any computer (Windows, macOS or Linux) to prepare the USB drive

## Start from scratch

From an empty machine to a running K-NAS. After the install, everything is done in the browser.

### 1. Download the K-NAS ISO

Download `debian-auto-installable.iso` from the [latest release](../../releases/latest).

### 2. Write it to a USB drive

Use [balenaEtcher](https://etcher.balena.io) (Windows, macOS, Linux): select the ISO, select your USB drive, and click Flash.

<details>
<summary>Fallback for macOS and Linux: use <code>dd</code></summary>

If Etcher fails, use the terminal. **`dd` erases the disk you point it at: double-check the name.**

On macOS (replace `disk4` with your USB drive, shown by `diskutil list`):

```bash
diskutil list
diskutil unmountDisk /dev/disk4
sudo dd if=~/Downloads/debian-auto-installable.iso of=/dev/rdisk4 bs=4m
diskutil eject /dev/disk4
```

On Linux (replace `sdX` with your USB drive, shown by `lsblk`):

```bash
lsblk
sudo dd if=~/Downloads/debian-auto-installable.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

`dd` prints nothing until it finishes: it may look frozen.

</details>

### 3. Install

Boot the NAS from the USB drive. The installer asks a few questions at the start, mainly your **username** and **password** (your Cockpit login, there is no default).

The boot menu waits for Enter, and the install **erases the disk you choose for the system**. With several disks, pick the smaller one (ideally the SSD) and keep the other for data. Then it installs Docker and Cockpit and reboots.

### 4. Open K-NAS in your browser

The first start downloads the apps (a few minutes). Then the NAS screen shows:

```
K-NAS is ready. Open http://<NAS-IP>:3000 on any device in your home.
```

Open it on your phone or computer. This is **Homepage**: links to every app and your free disk space. Reserve the NAS's IP in your router (DHCP reservation) so it never changes.

### 5. First steps

From the links on Homepage:

1. **Add your data disk** in **Cockpit** (`https://<NAS-IP>:9090`, log in, click **Turn on administrative access**). The certificate warning is expected. In **Storage**, format the disk as ext4 with mount point **`/mnt/storage`**. More disks go at `/mnt/<name>`, e.g. `/mnt/backup`.
2. **Start Immich** in **Dockge** (`http://<NAS-IP>:5001`, create an account on first visit). Open the `immich` stack, check `UPLOAD_LOCATION` is on your data disk, press **Start**. Then open Immich (`:2283`) and create your account.
3. **Set up backups** in **Backrest** (see [Backups](#backups)).

To browse or copy files, use **Files** in Cockpit.

## What runs on your NAS

| App | Address | What it is for | Login |
|---|---|---|---|
| [Homepage](https://gethomepage.dev) | `http://<NAS-IP>:3000` | Start page with links and disk space | none |
| [Cockpit](https://cockpit-project.org) | `https://<NAS-IP>:9090` | Disks, files, users, updates, logs, restart | your NAS user and password |
| [Dockge](https://github.com/louislam/dockge) | `http://<NAS-IP>:5001` | Start, stop, update and edit apps | created on first visit |
| [Backrest](https://github.com/garethgeorge/backrest) | `http://<NAS-IP>:9898` | Backups and restores | created on first visit |
| [Immich](https://immich.app) | `http://<NAS-IP>:2283` | Photos and videos from all your devices | created on first visit |
| [Jellyfin](https://jellyfin.org) | `http://<NAS-IP>:8096` | Watch your movies and series, on any device | created on first visit |
| [Seerr](https://github.com/seerr-team/seerr) | `http://<NAS-IP>:5055` | Ask for a movie or series | your Jellyfin user |
| [Radarr](https://radarr.video) / [Sonarr](https://sonarr.tv) | `:7878` / `:8989` | Find and download movies / series | none on your home network |
| [Prowlarr](https://prowlarr.com) | `http://<NAS-IP>:9696` | The torrent sites Radarr, Sonarr and Lidarr search | none on your home network |
| [qBittorrent](https://www.qbittorrent.org) | `http://<NAS-IP>:8085` | Downloads torrents | none on your home network |
| [Navidrome](https://www.navidrome.org) | `http://<NAS-IP>:4533` | Your music, in the browser and in music apps | created on first visit |
| [Lidarr](https://lidarr.audio) | `http://<NAS-IP>:8686` | Find and download music | none on your home network |
| [Mixarr](https://github.com/aquantumofdonuts/mixarr) | `https://<NAS-IP>:3443` | Discover new artists for Lidarr | created on first visit |
| [Pi-hole](https://pi-hole.net) | `http://<NAS-IP>:8080/admin` | Blocks ads and trackers on every device | password in its `.env` in Dockge |

The first visitor creates the account, so open each app soon after installing. Dockge and Cockpit control the whole machine: never forward their ports in your router.

The download apps (Radarr, Sonarr, Lidarr, Prowlarr, qBittorrent) need no login from your home network, and stay locked elsewhere. Trade-off: any device on your Wi-Fi can change your downloads (not your photos, files or system). To add a login: **Settings > General > Authentication** in the *arrs, or **Tools > Options > Web UI** in qBittorrent (turn off "Bypass authentication for clients in whitelisted IP subnets").

Homepage, Dockge and Backrest start at every boot. Other apps start from Dockge and keep running across reboots until you stop them.

## Listen to your music with Navidrome

1. Copy your music to `/mnt/storage/media/music` (Cockpit > **Files**). Any layout works, it reads the tags.
2. In Dockge, open the `navidrome` stack and press **Start** (set `MUSIC_FOLDER` in its `.env` first if your music is elsewhere).
3. Open `http://<NAS-IP>:4533` and create your account. New music is picked up by itself.

On your phone, use any Subsonic app (Symfonium or Tempo on Android, play:Sub or Amperfy on iPhone) with `http://<NAS-IP>:4533`.

## Find new music with Lidarr and Mixarr

**Lidarr** downloads albums of the artists you follow into `/mnt/storage/media/music`, where Navidrome plays them. It is in the `media` stack: start it and set up Prowlarr first ([Movies and series](#movies-and-series), steps 1 and 4).

1. **Lidarr** (`:8686`):
   - **Settings > Media Management > Add Root Folder:** `/data/music`.
   - **Settings > Download Clients > + > qBittorrent:** host `qbittorrent`, port `8085`, user and password empty.
   - In Prowlarr, **Settings > Apps > + > Lidarr**, with `http://lidarr:8686` and the API key from Lidarr's **Settings > General**.
2. Add an artist in Lidarr (**Library > Add New**). It downloads their albums, and they show up in Navidrome.

**Mixarr** suggests new artists (Spotify, Last.fm, Deezer...) and adds the ones you approve to Lidarr. It is a young project, in its own `mixarr` stack:

1. In Dockge, open the `mixarr` stack. In its `.env`, replace `NAS-IP` in `BASE_URL` with your NAS's IP, then press **Start**.
2. Open `https://<NAS-IP>:3443` (certificate warning is expected) and create your account.
3. In **Settings > Connections**, add Lidarr (`http://<NAS-IP>:8686` and its API key), then your music services.

## Movies and series

Ask for a movie or series in **Seerr**: it downloads and shows up in **Jellyfin**. All in the `media` stack:

```
Seerr (you ask) -> Radarr (movies) / Sonarr (series) -> Prowlarr (finds torrents)
  -> qBittorrent (downloads) -> Radarr / Sonarr (move it into the library) -> Jellyfin (you watch)
```

Everything goes in `/mnt/storage/media`: `downloads`, `movies`, `series`, `music` (see [Find new music](#find-new-music-with-lidarr-and-mixarr)). Finished downloads are linked, not copied, so they take no extra space while seeding.

Apps reach each other by name (like `radarr`), not by the NAS's IP.

Setup takes about 10 minutes, once:

1. **Start it.** In Dockge, open the `media` stack and press **Start**.
2. **Radarr** (`:7878`):
   - **Settings > Media Management > Add Root Folder:** `/data/movies`.
   - **Settings > Download Clients > + > qBittorrent:** host `qbittorrent`, port `8085`, user and password empty. **Test**, then **Save**.
3. **Sonarr** (`:8989`). The same as Radarr, with the root folder `/data/series`.
4. **Prowlarr** (`:9696`):
   - **Indexers > Add Indexer:** add the torrent sites you use.
   - **Settings > Apps > + > Radarr:** Prowlarr server `http://prowlarr:9696`, Radarr server `http://radarr:7878`, and Radarr's API key (**Settings > General**). Same for Sonarr (`http://sonarr:8989`) and Lidarr (`http://lidarr:8686`).
5. **Jellyfin** (`:8096`). Create your account, then add libraries: **Movies** from `/media/movies`, **Shows** from `/media/series`, and **Music** from `/media/music` if you like.
6. **Seerr** (`:5055`). Choose **Jellyfin**, server `jellyfin`, port `8096`, and log in with your Jellyfin user. Turn on the libraries, then add Radarr (server `radarr`, port `7878`, its API key, root folder `/data/movies`) and Sonarr (server `sonarr`, port `8989`, root folder `/data/series`).

Now ask for something in Seerr. Follow the download in qBittorrent; it appears in Jellyfin when done. On a TV or phone, use the Jellyfin app with `http://<NAS-IP>:8096`.

qBittorrent also works alone: add a torrent with **+**, it goes to `/mnt/storage/media/downloads`.

Peers see the NAS's public IP. Download only what you have the right to.

## Block ads with Pi-hole

Pi-hole blocks ads and trackers on every device at home, with nothing to install on them.

1. In Dockge, open the `pihole` stack and press **Start**. The web password is in its `.env` (random; change it and press **Update** if you like).
2. In your router, set the **DNS server** to the NAS's IP, with no second DNS server (devices would skip Pi-hole).
3. Open `http://<NAS-IP>:8080/admin` to see what is blocked or allow a broken site.

If the NAS is off, devices lose internet until you set the router's DNS back to automatic.

## Add more apps

Every app is a folder in `/opt/stacks` with a `compose.yaml`. In Dockge, click **Compose**, paste the app's Compose file and press **Deploy**. Keep its data on the data disk (e.g. `/mnt/storage/<app>`). Add a link in `/opt/stacks/homepage/config/services.yaml` (Cockpit > Files) to show it on Homepage.

## Updates

- **Debian** installs security updates daily. Other updates: Cockpit > **Software updates**.
- **Apps:** open the app in Dockge and press **Update**. Read the release notes first, especially for Immich.

## I already have Debian

Skip the ISO and run this on your Debian 13 (as a `sudo` user):

```bash
curl -fsSL https://raw.githubusercontent.com/AgustinMachiavello/K-NAS/main/install.sh | sudo bash
```

It puts K-NAS in `/opt/k-nas`, installs Docker and Cockpit, copies the apps to `/opt/stacks` and starts the core ones. Running it again updates K-NAS but keeps your apps.

## Backups

Backups use [Backrest](https://github.com/garethgeorge/backrest), a web page for [restic](https://restic.net): versioned, encrypted, and unchanged files take no extra space.

You need a second disk mounted in Cockpit (e.g. `/mnt/backup`): a copy on the same disk is lost with it.

1. In Backrest, **Add Repo**: type `local`, path `/mnt/backup/k-nas`, and a password. **Keep the password safe**: without it the backups are unreadable.
2. **Add Plan**: paths `/mnt/storage` and `/opt/stacks`, a schedule (for example daily) and how many versions to keep (for example 7 daily, 4 weekly, 6 monthly). Exclude `/opt/stacks/immich/postgres`: Immich backs up its own database nightly to the data disk, restore from that.
3. Press **Backup Now** for the first one.

To restore, open the plan in Backrest, pick a version, browse to the files and press **Restore**.

If the backup disk is not mounted, the backup fails instead of filling the system disk. For an off-site copy, add a cloud repository later (Backblaze B2, S3...).

## Move your data from an old disk

Plug in the old disk and mount it in Cockpit > **Storage** (e.g. `/mnt/old`). Copy files to `/mnt/storage` with Cockpit > **Files**, then unmount. Do not press **Format**: it erases the disk.

## How K-NAS is built

Plain Debian plus Docker, in three layers:

1. **OS:** Debian 13 via `os/debian/preseed.cfg`. `os/setup.sh` adds Docker, Cockpit and automatic security updates.
2. **Apps:** one Compose file per app in `stacks/`, copied to `/opt/stacks`.
3. **Control panels:** Homepage, Cockpit, Dockge, Backrest. They use normal Debian and Compose files, so you can manage the NAS without them.

The only K-NAS code running on the NAS is `os/boot.sh`: at every boot it shows the address, gives Homepage the IP and starts the core apps.

## If something does not work

- **An app does not open:** in Dockge, open it and read its log. **Restart** fixes most problems.
- **The address is `127.0.0.1`:** no network at boot. Check the cable and restart.
- **Apps did not download on first start:** it retries every 30 seconds until the internet works. See Cockpit > **Services** > `k-nas`.
