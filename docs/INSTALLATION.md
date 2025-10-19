# 📥 Installation Guide

Complete step-by-step installation guide for Odoo VirtualBox Manager.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [VirtualBox VM Setup](#virtualbox-vm-setup)
3. [Host Machine Setup](#host-machine-setup)
4. [Verification](#verification)
5. [Optional: SSH Key Authentication](#optional-ssh-key-authentication)

---

## Prerequisites

### Host Machine Requirements

- **Operating System:** Linux (Ubuntu/Debian recommended)
- **Python:** 3.7 or higher
- **sshpass:** For SSH password authentication
- **Git:** For cloning repository
- **Network:** Access to VirtualBox VM

### VirtualBox VM Requirements

- **Operating System:** Ubuntu Server 22.04/24.04
- **Odoo:** Version 11.0 installed
- **Python:** 3.7 in virtual environment
- **Network Adapter:** Bridged Adapter mode
- **SSH Server:** OpenSSH installed and running

---

## VirtualBox VM Setup

### Step 1: Configure Network Adapter

1. **Power off VM** (if running)
2. **VirtualBox Manager:**
   ```
   Select VM → Settings → Network → Adapter 1
   - Attached to: Bridged Adapter
   - Name: [Your physical network adapter]
   - Promiscuous Mode: Allow All
   ```
3. **Start VM**

### Step 2: Clone Repository (on Host)

```bash
git clone https://github.com/YOUR_USERNAME/odoo-virtualbox-manager.git
cd odoo-virtualbox-manager
```

### Step 3: Get Current VM IP

```bash
# Find VM's current IP (from VirtualBox console or SSH if you know IP)
ssh odoo@CURRENT_VM_IP
ip addr show | grep "inet " | grep -v 127.0.0.1
# Note the IP address (e.g., 192.168.1.123)
exit
```

### Step 4: Copy Setup Scripts to VM

```bash
# From host machine, in repository directory
cd odoo-virtualbox-manager

# Copy network setup script
scp vm-setup/setup-static-ip.sh odoo@CURRENT_VM_IP:/home/odoo/

# Copy Odoo run script
scp vm-setup/run.sh odoo@CURRENT_VM_IP:/home/odoo/
```

### Step 5: SSH into VM

```bash
ssh odoo@CURRENT_VM_IP
```

### Step 6: Make Scripts Executable

```bash
# In VM
chmod +x ~/setup-static-ip.sh
chmod +x ~/run.sh
```

### Step 7: Run Network Setup Script

```bash
# This will configure static IP ending in .101
sudo ./setup-static-ip.sh
```

**Follow the prompts:**

```
🔧 Odoo VirtualBox - Static IP Configuration
==============================================

✅ Found network interface: enp0s3

📡 Current network configuration:
   Interface: enp0s3
   Current IP: 192.168.1.123
   Gateway: 192.168.1.1

🎯 New static IP will be: 192.168.1.101

📝 Continue with this configuration? (y/n): y
```

**Press `y` and then `y` again when asked to apply.**

### Step 8: Note Your New IP

After completion:
```
📌 Your new static IP address is: 192.168.1.101

🔗 To connect via SSH from host machine:
   ssh odoo@192.168.1.101

📝 Add this to your host machine /etc/hosts:
   192.168.1.101    odoo-vm
```

**Write down this IP!** 📝

### Step 9: Verify SSH Connection

```bash
# Exit VM
exit

# Try new IP from host
ssh odoo@192.168.1.101

# Should connect successfully
exit
```

---

## Host Machine Setup

### Step 1: Install Dependencies

```bash
# Install sshpass
sudo apt update
sudo apt install sshpass

# Verify installation
sshpass -V
```

### Step 2: Add VM to /etc/hosts

```bash
# Replace 192.168.1.101 with your actual IP from Step 8
echo "192.168.1.101    odoo-vm" | sudo tee -a /etc/hosts

# Verify
cat /etc/hosts | grep odoo-vm
```

### Step 3: Test Hostname Resolution

```bash
# Ping test
ping -c 3 odoo-vm

# Should see:
# 64 bytes from odoo-vm (192.168.1.101): icmp_seq=1 ...
```

### Step 4: Configure Python Script

```bash
cd odoo-virtualbox-manager/scripts
nano odoo-restart.py
```

**Update these lines:**
```python
HOST = "odoo-vm"  # or use IP directly: "192.168.1.101"
USER = "odoo"
PASSWORD = "your_vm_password"  # Replace with actual password
REMOTE_SCRIPT = "/home/odoo/run.sh"
```

**Save:** `Ctrl+X` → `Y` → `Enter`

### Step 5: Test Python Script

```bash
python odoo-restart.py -d swisscapital --dev xml
```

**Expected output:**
```
📋 Arguments received: ['/path/to/odoo-restart.py', '-d', 'swisscapital', '--dev', 'xml']
🚀 Executing command:
sshpass -p *** ssh -o StrictHostKeyChecking=no odoo@odoo-vm bash /home/odoo/run.sh -d swisscapital --dev xml

🛑 Stopping existing Odoo processes...
ℹ️  No running Odoo processes found
🚀 Starting Odoo in developer mode (--dev=xml)
📝 Executing: /home/odoo/.venv/bin/python3.7 odoo-bin -c /mnt/odoo11/conf/odoo_vb.conf -d swisscapital --dev=xml
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2025-XX-XX XX:XX:XX,XXX INFO ? odoo: Odoo version 11.0
...
```

**Press `Ctrl+C` to stop.**

---

## Verification

### Checklist

- [ ] VM has static IP ending in .101
- [ ] Can ping `odoo-vm` from host
- [ ] Can SSH to `odoo@odoo-vm`
- [ ] Python script starts Odoo successfully
- [ ] Odoo stops when pressing Ctrl+C
- [ ] Can access Odoo web interface at `http://odoo-vm:8069`

### Test All Features

```bash
# 1. Start Odoo
python odoo-restart.py -d swisscapital --dev xml

# Wait for "HTTP service (werkzeug) running on ..."

# 2. Open browser
http://odoo-vm:8069

# 3. Stop with Ctrl+C
# Should see: "✅ Odoo stopped on VirtualBox"

# 4. Verify stopped
ssh odoo@odoo-vm "ps aux | grep odoo-bin"
# Should show no processes
```

---

## Optional: SSH Key Authentication

For password-less authentication (more secure):

### Step 1: Generate SSH Key (if you don't have one)

```bash
# On host machine
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Press Enter for all prompts (use default location)
```

### Step 2: Copy Key to VM

```bash
ssh-copy-id odoo@odoo-vm

# Enter password when prompted
```

### Step 3: Test Password-less Login

```bash
ssh odoo@odoo-vm
# Should login without password!
exit
```

### Step 4: Update Python Script (Optional)

You can remove the password and use a cleaner SSH command:

```python
# Instead of sshpass, use direct SSH
cmd = [
    "ssh", "-o", "StrictHostKeyChecking=no", f"{USER}@{HOST}",
    "bash", REMOTE_SCRIPT
]
```

---

## Troubleshooting Installation

### Issue: "sshpass: command not found"

```bash
sudo apt update
sudo apt install sshpass
```

### Issue: "No route to host"

```bash
# Check VM is running
VirtualBox → Select VM → Show

# Check IP is correct
ssh odoo@192.168.1.101

# Verify network adapter
VirtualBox → VM → Settings → Network → Adapter 1 → Bridged
```

### Issue: "Permission denied (publickey,password)"

```bash
# Check password in odoo-restart.py
# Try SSH manually to verify credentials
ssh odoo@odoo-vm
```

### Issue: "Address already in use" when starting Odoo

```bash
# Kill existing Odoo processes
ssh odoo@odoo-vm
pkill -f odoo-bin
exit
```

---

## Next Steps

- [Configuration Guide](CONFIGURATION.md) - Customize settings
- [Usage Examples](../README.md#usage) - Learn all commands
- [PyCharm Integration](../examples/pycharm/) - IDE setup
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

---

**Installation Complete! 🎉**

You're ready to start developing with Odoo in VirtualBox!