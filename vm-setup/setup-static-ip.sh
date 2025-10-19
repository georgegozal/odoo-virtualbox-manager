#!/bin/bash
# ===============================================================
# Odoo VirtualBox - Static IP Setup Script
# ===============================================================
# ეს სკრიპტი ავტომატურად აყენებს სტატიკურ IP-ს .101 ბოლოში
# ნებისმიერ ქსელში: 192.168.1.101, 192.168.100.101, და ა.შ.
# ===============================================================

set -e

echo "🔧 Odoo VirtualBox - Static IP Configuration"
echo "=============================================="
echo ""

# Root privileges შემოწმება
if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# ინტერფეისის აღმოჩენა (lo-ს გარეშე)
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

if [ -z "$INTERFACE" ]; then
    echo "❌ No active network interface found!"
    exit 1
fi

echo "✅ Found network interface: $INTERFACE"
echo ""

# მიმდინარე IP და Gateway-ის აღმოჩენა
CURRENT_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n1)

if [ -z "$CURRENT_IP" ] || [ -z "$GATEWAY" ]; then
    echo "❌ Could not detect current IP or gateway!"
    echo "   Current IP: $CURRENT_IP"
    echo "   Gateway: $GATEWAY"
    exit 1
fi

echo "📡 Current network configuration:"
echo "   Interface: $INTERFACE"
echo "   Current IP: $CURRENT_IP"
echo "   Gateway: $GATEWAY"
echo ""

# Network prefix გამოთვლა (192.168.1.x → 192.168.1)
NETWORK_PREFIX=$(echo $GATEWAY | cut -d'.' -f1-3)
NEW_IP="${NETWORK_PREFIX}.101"

echo "🎯 New static IP will be: $NEW_IP"
echo ""

# დადასტურება
read -p "📝 Continue with this configuration? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Configuration cancelled."
    exit 0
fi

echo ""
echo "🚀 Starting configuration..."
echo ""

# Backup ძველი კონფიგურაციის
BACKUP_DIR="/root/netplan-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r /etc/netplan/* "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup created: $BACKUP_DIR"

# Cloud-init გამორთვა
if [ -f /etc/cloud/cloud.cfg ]; then
    echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    echo "✅ Cloud-init network config disabled"
fi

# ძველი ფაილების გამორთვა
for file in /etc/netplan/*.yaml; do
    if [ -f "$file" ]; then
        mv "$file" "${file}.disabled" 2>/dev/null || true
    fi
done

# ახალი netplan კონფიგურაცია
NETPLAN_FILE="/etc/netplan/01-static-ip.yaml"

cat > "$NETPLAN_FILE" << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $NEW_IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
          - 1.1.1.1
EOF

echo "✅ Netplan configuration created: $NETPLAN_FILE"

# Permissions
chmod 600 "$NETPLAN_FILE"

echo ""
echo "🔍 Generated configuration:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$NETPLAN_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Netplan სინტაქსის შემოწმება
echo "🔍 Validating configuration..."
if ! netplan generate 2>/dev/null; then
    echo "❌ Configuration validation failed!"
    echo "   Restoring backup..."
    rm "$NETPLAN_FILE"
    cp -r "$BACKUP_DIR"/* /etc/netplan/
    netplan apply
    exit 1
fi

echo "✅ Configuration is valid"
echo ""

# გამაფრთხილებელი შეტყობინება
echo "⚠️  WARNING: Network connection will be interrupted!"
echo "   If something goes wrong, use VirtualBox console to restore."
echo ""
read -p "🚦 Apply configuration now? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Configuration saved but not applied."
    echo "   To apply later, run: sudo netplan apply"
    exit 0
fi

echo ""
echo "🔄 Applying network configuration..."

# Netplan apply
if netplan apply; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Configuration applied successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📌 Your new static IP address is: $NEW_IP"
    echo ""
    echo "🔗 To connect via SSH from host machine:"
    echo "   ssh odoo@$NEW_IP"
    echo ""
    echo "📝 Add this to your host machine /etc/hosts:"
    echo "   $NEW_IP    odoo-vm"
    echo ""
    echo "🎉 Configuration complete!"
else
    echo ""
    echo "❌ Failed to apply configuration!"
    echo "   Restoring backup..."
    cp -r "$BACKUP_DIR"/* /etc/netplan/
    netplan apply
    exit 1
fi