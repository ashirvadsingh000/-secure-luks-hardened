#!/bin/bash
set -euo pipefail

# =================================================
# CONFIG — EDIT ONLY DEVICE IF NEEDED
# =================================================
DEVICE="/dev/sdd"                     # ⚠️ CHANGE CAREFULLY
PARTITION="${DEVICE}1"
MAPPER_NAME="secureHDD"
FS_LABEL="SecureData"

MOUNT_POINT="/mnt/secure"
KEYDIR="/root/.keys"
KEYFILE="${KEYDIR}/${MAPPER_NAME}.key"

# =================================================
# ARGON2id HARDENING
# =================================================
PBKDF="argon2id"
MEMORY_KB=1048576        # 1 GB RAM
ITERATIONS=6
PARALLEL=4

# =================================================
# FLAGS
# =================================================
ACTION="${1:-}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

# =================================================
# HELPERS
# =================================================
log() { echo "▶ $1"; }
die() { echo "❌ $1"; exit 1; }

run() {
  if $DRY_RUN; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

get_password() {
  echo "🔑 Enter LUKS password (hidden — normal)"
  stty -echo
  read -rp "Password: " PASS
  echo
  stty echo
}

# =================================================
# DEPENDENCIES
# =================================================
deps() {
  run "apt update"
  run "apt install -y cryptsetup exfatprogs util-linux"
}

# =================================================
# CREATE (DESTROYS DISK)
# =================================================
create_disk() {
  [[ $EUID -eq 0 ]] || die "Run as root"
  [[ -b "$DEVICE" ]] || die "Device not found"

  echo "🚨 THIS WILL ERASE:"
  lsblk "$DEVICE"
  echo
  read -rp "Type ERASE to continue: " CONFIRM
  [[ "$CONFIRM" == "ERASE" ]] || exit 1

  deps

  log "Wiping signatures"
  run "wipefs -a $DEVICE"

  log "Partitioning disk"
  run "parted -s $DEVICE mklabel gpt"
  run "parted -s $DEVICE mkpart primary 0% 100%"
  sleep 2

  get_password; PASS1="$PASS"
  get_password; PASS2="$PASS"
  [[ "$PASS1" == "$PASS2" ]] || die "Passwords do not match"

  log "Generating keyfile"
  run "mkdir -p $KEYDIR"
  run "dd if=/dev/urandom of=$KEYFILE bs=4096 count=1"
  run "chmod 0400 $KEYFILE"

  log "Creating hardened LUKS2 container"
  run "echo -n '$PASS1' | cryptsetup luksFormat $PARTITION \
    --type luks2 \
    --pbkdf $PBKDF \
    --pbkdf-memory $MEMORY_KB \
    --pbkdf-parallel $PARALLEL \
    --pbkdf-force-iterations $ITERATIONS \
    --key-file=-"

  log "Adding keyfile as second factor"
  run "echo -n '$PASS1' | cryptsetup luksAddKey $PARTITION $KEYFILE -"

  unset PASS PASS1 PASS2

  run "cryptsetup open $PARTITION $MAPPER_NAME --key-file $KEYFILE"

  log "Formatting filesystem"
  run "mkfs.exfat /dev/mapper/$MAPPER_NAME -n $FS_LABEL"

  log "Mounting volume"
  run "mkdir -p $MOUNT_POINT"
  run "mount /dev/mapper/$MAPPER_NAME $MOUNT_POINT"

  configure_crypttab

  echo "✅ CREATE COMPLETE"
}

# =================================================
# AUTO-MOUNT CONFIG
# =================================================
configure_crypttab() {
  UUID=$(blkid -s UUID -o value "$PARTITION")

  CRYPTTAB_LINE="$MAPPER_NAME UUID=$UUID $KEYFILE luks"
  FSTAB_LINE="/dev/mapper/$MAPPER_NAME $MOUNT_POINT exfat defaults 0 0"

  if ! grep -q "$MAPPER_NAME" /etc/crypttab; then
    log "Updating /etc/crypttab"
    run "echo '$CRYPTTAB_LINE' >> /etc/crypttab"
  fi

  if ! grep -q "$MAPPER_NAME" /etc/fstab; then
    log "Updating /etc/fstab"
    run "echo '$FSTAB_LINE' >> /etc/fstab"
  fi
}

# =================================================
# MOUNT
# =================================================
mount_disk() {
  run "cryptsetup open $PARTITION $MAPPER_NAME --key-file $KEYFILE"
  run "mkdir -p $MOUNT_POINT"
  run "mount /dev/mapper/$MAPPER_NAME $MOUNT_POINT"
  echo "📂 Mounted at $MOUNT_POINT"
}

# =================================================
# UNMOUNT
# =================================================
umount_disk() {
  run "umount $MOUNT_POINT"
  run "cryptsetup close $MAPPER_NAME"
  echo "🔒 Unmounted and locked"
}

# =================================================
# ROUTER
# =================================================
case "$ACTION" in
  create) create_disk ;;
  mount) mount_disk ;;
  umount) umount_disk ;;
  *) echo "Usage: $0 {create|mount|umount} [--dry-run]" ;;
esac
