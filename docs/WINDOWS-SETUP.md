# 🪟 Windows Setup Guide

Complete setup guide for Odoo VirtualBox Manager on Windows 10/11.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install Required Software](#install-required-software)
3. [VirtualBox VM Setup](#virtualbox-vm-setup)
4. [SSH Configuration](#ssh-configuration)
5. [Python Script Setup](#python-script-setup)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Operating System:** Windows 10 (build 1809+) or Windows 11
- **VirtualBox:** 6.0 or higher
- **Python:** 3.7 or higher
- **RAM:** Minimum 8GB (4GB for VM, 4GB for host)
- **Disk Space:** Minimum 50GB free

---

## Install Required Software

### Step 1: Install Python

1. **Download Python:**
   - Go to: https://www.python.org/downloads/
   - Download Python 3.11 (or latest 3.x)

2. **Install Python:**
   - ✅ **IMPORTANT:** Check "Add Python to PATH"
   - Click "Install Now"

3. **Verify installation:**
   ```cmd
   python --version
   ```
   Should show: `Python 3.11.x` or similar

---

### Step 2: Install OpenSSH Client

1. **Open Settings:**
   ```
   Windows Key → Settings → Apps → Optional Features
   ```

2. **Add OpenSSH Client:**
   - Click "Add a feature"
   - Search: "OpenSSH Client"
   - Click "Install"

3. **Verify installation:**
   ```cmd
   ssh -V
   ```
   Should show: `OpenSSH_for_Windows_x.x`

---

### Step 3: Install VirtualBox

1. **Download VirtualBox:**
   - Go to: https://www.virtualbox.org/wiki/Downloads
   - Download "Windows hosts"

2. **Install VirtualBox:**
   - Run installer
   - Accept all defaults

---

## VirtualBox VM Setup

### Step 1: Import OVA File

1. **Open VirtualBox**
2. **Import Appliance:**
   ```
   File → Import Appliance → Browse → Select Ubuntu Server.ova
   ```
3. **Settings (before first start):**
   ```
   VM → Settings → Network → Adapter 1
   - Attached to: Bridged Adapter
   - Name: [Your active network adapter]
   ```

---

### Step 2: Start VM and Configure Static IP

1. **Start VM:**
   ```
   Right-click VM → Start → Normal Start
   ```

2. **Login:**
   ```
   Username: odoo
   Password: 1234
   ```

3. **Run IP setup script:**
   ```bash
   sudo ./setup-static-ip.sh
   ```

4. **Note the IP address:**
   ```
   📌 Your new static IP address is: 192.168.X.101
   ```
   **Write this down!** 📝

---

## SSH Configuration

### Method 1: Automated Setup (Recommended)

1. **Open Command Prompt** (as regular user, not Administrator):
   ```cmd
   cd C:\path\to\odoo-virtualbox-manager
   ```

2. **Run SSH setup script:**
   ```cmd
   setup-ssh-keys.bat
   ```

3. **Follow the prompts:**
   - Enter VM IP address (e.g., `192.168.1.101`)
   - Enter VM password when prompted: `1234`
   - Choose to add to hosts file: `y`

**Done!** SSH key is configured.

---

### Method 2: Manual Setup

#### Step 1: Generate SSH Key

```cmd
ssh-keygen -t rsa -b 4096 -f %USERPROFILE%\.ssh\id_rsa -N ""
```

#### Step 2: Copy Key to VM

```cmd
type %USERPROFILE%\.ssh\id_rsa.pub | ssh odoo@192.168.1.101 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

Enter password: `1234`

#### Step 3: Test Connection

```cmd
ssh odoo@192.168.1.101
```

Should connect without password!

---

### Step 4: Add VM to Hosts File

**Option A: Manual (Requires Administrator)**

1. **Open Notepad as Administrator:**
   ```
   Right-click Notepad → Run as Administrator
   ```

2. **Open hosts file:**
   ```
   File → Open → C:\Windows\System32\drivers\etc\hosts
   ```

3. **Add line:**
   ```
   192.168.1.101    odoo-vm
   ```

4. **Save file**

**Option B: Command Line (Requires Administrator)**

```cmd
echo 192.168.1.101    odoo-vm >> C:\Windows\System32\drivers\etc\hosts
```

---

### Step 5: Test Hostname

```cmd
ping odoo-vm
```

Should respond from `192.168.1.101`

---

## Python Script Setup

### Step 1: Clone Repository

```cmd
cd C:\Users\YourName\Documents
git clone https://github.com/YOUR_USERNAME/odoo-virtualbox-manager.git
cd odoo-virtualbox-manager
```

### Step 2: Verify Script

Check that `scripts\odoo-restart-windows.py` exists:

```cmd
dir scripts\odoo-restart-windows.py
```

### Step 3: Edit Configuration (if needed)

Open `scripts\odoo-restart-windows.py` and verify:

```python
HOST = "odoo-vm"  # or use IP: "192.168.1.101"
USER = "odoo"
SSH_KEY = os.path.expanduser("~/.ssh/id_rsa")
```

---

## Verification

### Test 1: Start Odoo

```cmd
cd C:\path\to\odoo-virtualbox-manager
python scripts\odoo-restart-windows.py -d swisscapital --dev xml
```

**Expected output:**
```
🪟 Odoo VirtualBox Manager (Windows Edition)
==================================================

📋 Arguments received: ['scripts\\odoo-restart-windows.py', '-d', 'swisscapital', '--dev', 'xml']
🚀 Executing command:
ssh -o StrictHostKeyChecking=no odoo@odoo-vm bash /home/odoo/run.sh -d swisscapital --dev xml

🛑 Stopping existing Odoo processes...
ℹ️  No running Odoo processes found
⚙️  Config file not specified, using default: odoo_vb.conf
✅ Using config file: /mnt/odoo11/conf/odoo_vb.conf
🚀 Starting Odoo in developer mode (--dev=xml)
...
```

---

### Test 2: Stop Odoo

Press `Ctrl+C` in the terminal.

**Expected output:**
```
⚠️  Interrupted by user (Ctrl+C)
🛑 Stopping Odoo on VirtualBox...
✅ Odoo stopped on VirtualBox
```

---

### Test 3: Access Web Interface

Open browser:
```
http://odoo-vm:8069
```

Should see Odoo login page! 🎉

---

## Troubleshooting

### ❌ "python: command not found"

**Solution:** Python not in PATH

1. **Find Python location:**
   ```cmd
   where python
   ```

2. **Add to PATH manually:**
   ```
   Windows Key → "Environment Variables"
   → System Variables → Path → Edit
   → Add: C:\Users\YourName\AppData\Local\Programs\Python\Python311
   ```

---

### ❌ "ssh: command not found"

**Solution:** Install OpenSSH Client

```
Settings → Apps → Optional Features → Add "OpenSSH Client"
```

---

### ❌ "Permission denied (publickey)"

**Solution:** SSH key not copied correctly

```cmd
REM Re-run setup
setup-ssh-keys.bat
```

---

### ❌ "Could not resolve hostname odoo-vm"

**Solution:** Not in hosts file

1. **Check hosts file:**
   ```cmd
   type C:\Windows\System32\drivers\etc\hosts | findstr odoo-vm
   ```

2. **If empty, add manually** (as Administrator):
   ```cmd
   echo 192.168.1.101    odoo-vm >> C:\Windows\System32\drivers\etc\hosts
   ```

---

### ❌ "Connection timed out"

**Solution:** Check VM and network

```cmd
REM 1. Check VM is running
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list runningvms

REM 2. Ping VM
ping 192.168.1.101

REM 3. Check SSH
ssh odoo@192.168.1.101
```

---

### ❌ Encoding errors in terminal

**Solution:** Use UTF-8 encoding

```cmd
REM Add to top of script or run before starting:
chcp 65001
```

---

## PowerShell Alternative

If you prefer PowerShell:

```powershell
# Start Odoo
python scripts\odoo-restart-windows.py -d swisscapital --dev xml

# Or with PowerShell's native SSH
ssh odoo@odoo-vm "bash /home/odoo/run.sh -d swisscapital --dev xml"
```

---

## IDE Integration (PyCharm on Windows)

### PyCharm Configuration

1. **Create Run Configuration:**
   ```
   Run → Edit Configurations → + → Python
   
   Name: Odoo VirtualBox Start
   Script path: C:\path\to\odoo-virtualbox-manager\scripts\odoo-restart-windows.py
   Parameters: -d swisscapital --dev xml
   Python interpreter: [Your Python 3.7+]
   Working directory: C:\path\to\odoo-virtualbox-manager
   ```

2. **Use Run/Stop buttons:**
   - ▶️ **Run** - Starts Odoo
   - ⏹️ **Stop** - Stops Odoo (Ctrl+C)

---

## Quick Start Script (Optional)

Create `start-odoo.bat`:

```batch
@echo off
cd C:\path\to\odoo-virtualbox-manager
python scripts\odoo-restart-windows.py -d swisscapital --dev xml
pause
```

Double-click to start Odoo!

---

## Next Steps

- [Configuration Guide](../docs/CONFIGURATION.md) - Customize settings
- [Troubleshooting](../docs/TROUBLESHOOTING.md) - Common issues
- [Usage Examples](../README.md#usage) - Learn all commands

---

**Windows Setup Complete! 🎉**

You're ready to develop with Odoo on Windows!