#!/bin/bash
# Reset to DHCP

sudo systemctl stop systemd-networkd
sudo rm /etc/netplan/01-static-ip.yaml 2>/dev/null || true
sudo rm /etc/netplan/*.yaml.disabled 2>/dev/null || true

# Create simple DHCP config
cat << EOF | sudo tee /etc/netplan/00-installer-config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
EOF

sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan apply