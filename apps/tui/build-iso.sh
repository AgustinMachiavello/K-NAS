#!/bin/bash

# Exit immediately if Docker is not running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

echo "Building automated Debian ISO..."

# Move to the repo root
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

# Run a temporary Debian container. The Debian folder (ISO and preseed.cfg) is /data, the repo is /repo
docker run --rm -v "$(pwd)/os/debian:/data" -v "$(pwd):/repo:ro" debian:bookworm-slim bash -c "
  # 1. Install required ISO manipulation utilities inside the container
  DEBIAN_FRONTEND=noninteractive apt-get update -qq && apt-get install -y -qq xorriso p7zip-full > /dev/null && \

  # 2. Extract the contents of the original Debian ISO
  mkdir -p /tmp/iso && \
  #    (skip the generated ISO so rebuilding doesn't pick it up as the source)
  SRC_ISO=\$(ls /data/*.iso | grep -v '/debian-auto-installable.iso\$' | head -n 1) && \
  [ -n \"\$SRC_ISO\" ] || { echo 'Error: no source Debian ISO found in os/debian/'; exit 1; } && \
  7z x \"\$SRC_ISO\" -o/tmp/iso > /dev/null && \

  # 3. Copy preseed.cfg to the root of the extracted ISO
  cp /data/preseed.cfg /tmp/iso/preseed.cfg && \

  # 4. Copy K-NAS onto the ISO, the installer copies it to the new system
  mkdir -p /tmp/iso/k-nas && \
  cp -r /repo/apps /tmp/iso/k-nas/apps && \
  cp /data/late-command.sh /tmp/iso/k-nas/late-command.sh && \

  # 5. Overwrite GRUB configuration with the unattended install entry. No timeout: the install erases a disk, so it only starts when someone presses Enter
  printf 'set default=\"0\"\nset timeout=-1\n\nmenuentry \"K-NAS install: ERASES the disk it installs on (press Enter to start)\" {\n    set background_color=black\n    linux /install.amd/vmlinuz auto=true priority=high file=/cdrom/preseed.cfg quiet ---\n    initrd /install.amd/initrd.gz\n}\n' > /tmp/iso/boot/grub/grub.cfg && \

  # 6. Re-pack the modified filesystem into a bootable hybrid UEFI/BIOS ISO
  xorriso -as mkisofs \
    -r -V 'DEBIAN_AUTO' \
    -J -joliet-long \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    -o /data/debian-auto-installable.iso \
    /tmp/iso > /dev/null 2>&1
"

echo "Done. Created debian-auto-installable.iso"