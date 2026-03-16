# 🔐 secure-luks-hardened

☢️ Critical Warning — Disk Selection is a One-Way Operation

## Enterprise-Grade LUKS Disk Encryption Automation Script

A production-ready Bash script for secure creation, management, and automated mounting of encrypted disk volumes using LUKS2 with Argon2id key derivation, hardware-backed keyfile authentication, and systemd integration.

---

## Overview

`secure-luks-hardened` provides a comprehensive solution for implementing enterprise-grade disk encryption on Linux systems. This script automates the entire lifecycle of LUKS2 encrypted volumes, from initial setup through operational management, ensuring compliance with modern cryptographic standards and security best practices.

---

## ⚡ Key Features

- **Disk Partitioning & Wiping**: Secure erasure of target device with cryptographic wipe
- **LUKS2 Encryption**: Modern cryptographic container with Argon2id key derivation
- **Dual Authentication**: Password and keyfile-based access control
- **Memory-Hard KDF**: Argon2id with 1GB memory allocation resistant to brute-force attacks
- **exFAT Formatting**: Cross-platform filesystem compatibility
- **Automated Mounting**: systemd-integrated auto-mount at system boot
- **Dry-Run Mode**: Non-destructive validation before execution

---

## ⚠️ Critical Pre-Execution Warnings

**This script performs destructive operations and will completely erase the selected disk.**

### Before Execution:

1. ✓ Verify the `DEVICE` variable in the script configuration
2. ✓ Confirm the target disk is correctly identified
3. ✓ Back up all critical data from the target device
4. ✓ Ensure no active processes access the target disk

---

## ⚙️ Configuration

Edit the following variables in `secure-luks-hardened.sh` prior to execution:

```bash
DEVICE="/dev/sdd"              # Target disk device
MOUNT_POINT="/mnt/secure"      # Mount directory
KEYFILE_PATH="/root/.keys/secureHDD.key"
```

---

## 🔐 Cryptographic Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| **Algorithm** | Argon2id | Memory-hard key derivation |
| **Memory Cost** | 1GB | Resistance to parallel attacks |
| **Time Cost** | 6 | Iteration count |
| **Parallelism** | 4 | Concurrent threads |

These parameters significantly increase computational cost for brute-force attacks.

---

## 📦 Installation & Setup

```bash
# Download and prepare
git clone <repository>
cd secure-luks-hardened

# Grant execution permissions
chmod +x secure-luks-hardened.sh

# Create encrypted disk
sudo ./secure-luks-hardened.sh create
```

---

## 📋 Command Reference

### Create Encrypted Volume
```bash
sudo ./secure-luks-hardened.sh create
```

### Mount Encrypted Disk
```bash
sudo ./secure-luks-hardened.sh mount
```

### Unmount Encrypted Disk
```bash
sudo ./secure-luks-hardened.sh umount
```

### Dry-Run (Validation Mode)
```bash
sudo ./secure-luks-hardened.sh create --dry-run
```

---

## 📝 Documentation: System Paths & Artifacts Section

### Overview
This section documents the system paths and artifacts used throughout the secure LUKS hardened setup.

### ⚠️ Critical: Disk Name Selection

**Importance:** Selecting the correct disk name is crucial and a major issue. Selecting the wrong disk will result in data loss on that disk.

### 🔍 How to Find Your Disk Name

1. **List all disks:**
    ```bash
    lsblk
    ```
    or
    ```bash
    sudo fdisk -l
    ```

2. **Identify your target disk:**
    - Look for disk size matching your intended LUKS target
    - Note the device name (e.g., `/dev/sda`, `/dev/nvme0n1`, `/dev/sdb`)
    - **Verify twice** before proceeding

3. **Common disk naming conventions:**
    - SATA/USB: `/dev/sd[a-z]` (sda, sdb, sdc, etc.)
    - NVMe: `/dev/nvme[0-9]n[0-9]` (nvme0n1, nvme1n1, etc.)
    - Loop devices: `/dev/loop[0-9]`

### 📍 Where to Place the Disk Name

The disk name variable should be defined at the beginning of your configuration/scripts:

## 📂 System Paths & Artifacts

| Path | Purpose | Permissions |
|------|---------|-------------|
| `/root/.keys/secureHDD.key` | Encrypted keyfile | `600` (root-only) |
| `/mnt/secure` | Mount point | `700` |
| `/etc/crypttab` | LUKS mapping config | `600` |
| `/etc/fstab` | Filesystem mount config | `644` |

---

## 🔄 Automatic Boot Integration

The script automatically configures:

- **crypttab**: LUKS device mapping with keyfile authentication
- **fstab**: Encrypted volume mount configuration with systemd-compatible options

The encrypted volume will mount automatically during system startup with full security context preserved.

---

## 🛠 System Dependencies

The following packages are installed automatically:

- **cryptsetup** — LUKS encryption management
- **exfatprogs** — exFAT filesystem utilities
- **util-linux** — Core Linux utilities

---

## 📈 Enterprise Use Cases

- Secure external drive management
- Developer workstation encryption
- Automated backup storage protection
- Cybersecurity laboratory environments
- Compliance-driven data storage
- Multi-tenant secure storage isolation

---

## ❗ Known Limitations

- Linux systems only
- Requires root/sudoer privileges
- exFAT filesystem (no native journaling)
- Local keyfile storage (no remote key management)
- Single device per script invocation

---

## 🚀 Roadmap

- [ ] ext4/btrfs filesystem support
- [ ] TPM 2.0 integration
- [ ] SSH-based remote unlock capability
- [ ] Interactive CLI with guided configuration
- [ ] Multi-device batch operations
- [ ] Audit logging and forensic support

---

## 🤝 Contributing

Contributions are welcome. Please review the contribution guidelines and submit pull requests following the established code standards.

---

## 📜 License

MIT License — See LICENSE file for details

