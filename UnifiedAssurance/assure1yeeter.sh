#!/bin/bash

# Make sure we are running as root
if [ "$EUID" -ne 0 ]; then
  echo "!! ERROR !! Please run this script with sudo or as root."
  exit 1
fi

echo "Starting complete wipe of Unified Assurance (Assure1)..."

echo "[1/5] Uninstalling the Assure1 RPM package..."
dnf erase Assure1 -y

echo "[2/5] Hunting down and killing leftover processes and ports..."
# Kill anything with 'assure1' in the name
pkill -9 -f assure1 2>/dev/null
# Free up the database and messaging ports
fuser -k 3306/tcp 2>/dev/null
fuser -k 7627/tcp 2>/dev/null

echo "[3/5] Obliterating the installation directories..."
rm -rf /opt/assure1

echo "[4/5] Removing the assure1 system user..."
userdel assure1 2>/dev/null
groupdel assure1 2>/dev/null

echo "[5/5] Purging SSL certificates from the OS trust store..."
rm -f /etc/pki/ca-trust/source/Assure1_*
update-ca-trust

echo "=========================================================="
echo "Wipe complete! The server is now a clean slate."
echo "Your original zip and RPM files in /opt/install/ are safe."
echo "=========================================================="
