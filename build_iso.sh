#!/bin/bash
# build_iso.sh — builds a bootable JARVIS OS Linux ISO using live-build.
#
# MUST run on a real Debian/Ubuntu Linux machine (or WSL2, or a VM, or the
# GitHub Actions workflow in ../.github/workflows/build-iso.yml) — it needs
# `lb` (live-build) and root/sudo, and downloads ~500MB-1GB of base packages
# from the internet during the build. Takes 15-40 minutes. Final ISO is
# usually 1.5-3 GB.
#
# Usage:
#   cd iso_builder
#   sudo ./build_iso.sh

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this with sudo: sudo ./build_iso.sh"
    exit 1
fi

echo "=== JARVIS OS ISO Builder ==="

# 1. Install live-build if missing
if ! command -v lb >/dev/null 2>&1; then
    echo "Installing live-build..."
    apt-get update
    apt-get install -y live-build
fi

# 2. Copy the JARVIS OS project into the live filesystem image
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="config/includes.chroot/opt/jarvis-os"

echo "Copying project from $PROJECT_ROOT into $TARGET ..."
mkdir -p "$TARGET"
rsync -a --delete \
    --exclude 'iso_builder' \
    --exclude '.git' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'SampleProject' \
    --exclude 'HospitalManagement' \
    --exclude 'BankingSoftware' \
    --exclude 'DemoProject' \
    --exclude 'JarvisTest' \
    --exclude 'JarvisBackup' \
    --exclude 'config/api_keys.json' \
    "$PROJECT_ROOT"/ "$TARGET"/

# 3. Configure live-build (Debian bookworm, hybrid ISO that boots on USB or VM)
if [ ! -f config/binary ]; then
    echo "Running lb config..."
    lb config \
        --distribution bookworm \
        --archive-areas "main contrib non-free non-free-firmware" \
        --binary-images iso-hybrid \
        --debian-installer none
fi

# 4. Build
echo "Building ISO — this takes a while..."
lb build

echo
echo "=== Build finished ==="
ls -lh *.iso 2>/dev/null || echo "No .iso found — check the build log above for errors."
