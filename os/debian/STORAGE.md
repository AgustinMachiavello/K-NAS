# Setting Up Storage on Debian

Reference for preparing a second disk (HDD) on a Debian server: partitioning, formatting, mounting, folder structure, and permissions.

Copy-paste each block into your terminal, one at a time.

⚠️ Always check `lsblk` before partitioning. Partitioning the wrong disk erases its data.

## 1. Identify the disk

```bash
# List all disks and their sizes
lsblk
```

The system disk shows partitions and mount points (`/`, `/boot/efi`, `[SWAP]`). The new disk shows no partitions and no mount point. That's the one you're preparing (here, `/dev/sdb`).

## 2. Partition the disk

```bash
# Open the partitioning tool on the new disk
sudo fdisk /dev/sdb
```

Inside `fdisk`, type each of these one at a time, then Enter:

```
g
```
Creates a new GPT partition table.

```
n
```
Creates a new partition. Press Enter through the prompts to use the full disk.

```
w
```
Writes the changes and exits. Nothing is written until this step.

## 3. Format the partition

```bash
# Format as ext4
sudo mkfs.ext4 /dev/sdb1
```

## 4. Create a mount point and get the UUID

```bash
# Create the folder where the disk will be accessible
sudo mkdir -p /mnt/storage
```

```bash
# Get the disk's unique ID
sudo blkid /dev/sdb1
```
Copy the `UUID="..."` value for the next step.

## 5. Mount the disk permanently

```bash
# Open the file that controls disks mounted at boot
sudo nano /etc/fstab
```

Add this line at the end (use your own UUID):

```
UUID=your-disk-uuid-here /mnt/storage ext4 defaults 0 2
```

Save and exit nano: `Ctrl+O`, `Enter`, `Ctrl+X`.

```bash
# Reload systemd
sudo systemctl daemon-reload
```

```bash
# Mount everything in fstab
sudo mount -a
```

```bash
# Verify it mounted with the expected space
df -h /mnt/storage
```

## 6. Create the folder structure

```bash
# Create all top-level folders
sudo mkdir -p /mnt/storage/media/{movies,series,music,photos,audiobooks,ebooks,games} /mnt/storage/documents /mnt/storage/repos /mnt/storage/shared /mnt/storage/software /mnt/storage/downloads /mnt/storage/docker /mnt/storage/backups/staging
```

Result:

```
/mnt/storage/
├── media/
│   ├── movies/
│   ├── series/
│   ├── music/
│   ├── photos/
│   ├── audiobooks/
│   ├── ebooks/
│   └── games/
├── documents/
├── repos/
├── shared/
├── software/
├── downloads/
├── docker/
└── backups/staging/
```

`docker/` holds each service's persistent data. `backups/staging/` is a temporary landing spot for dumps, not the real backup (a real backup lives on separate hardware).

## 7. Check your user's ID

```bash
# Show your normal user's UID and GID
id $USER
```
Debian assigns `1000` to the first regular user created during install. Root is always `0`.

## 8. Set folder ownership

```bash
# Make your normal user the owner of everything under /mnt/storage
sudo chown -R $USER:$USER /mnt/storage
```

```bash
# Verify ownership
ls -la /mnt/storage
```

This matters for Docker later. Containers configured with `PUID=1000`/`PGID=1000` read and write to `/mnt/storage` with the same permissions as your own user. Nothing more.