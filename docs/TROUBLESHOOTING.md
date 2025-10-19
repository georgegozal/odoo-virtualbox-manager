# 🔧 Troubleshooting Guide

Common issues and solutions for Odoo VirtualBox Manager.

---

## 📋 Table of Contents

- [Connection Issues](#connection-issues)
- [Network Problems](#network-problems)
- [Odoo Startup Issues](#odoo-startup-issues)
- [Process Management](#process-management)
- [Performance Issues](#performance-issues)
- [VirtualBox Issues](#virtualbox-issues)

---

## Connection Issues

### ❌ "Permission denied (publickey,password)"

**Symptoms:**
```bash
odoo@192.168.1.101: Permission denied (publickey,password).
```

**Causes:**
1. Wrong password in `odoo-restart.py`
2. SSH not accepting password authentication
3. Wrong username

**Solutions:**

**Solution 1: Check password**
```python
# In odoo-restart.py
PASSWORD = "1234"  # Make sure this matches VM password
```

**Solution 2: Test SSH manually**
```bash
ssh odoo@odoo-vm
# Enter password manually to verify credentials
```

**Solution 3: Enable password authentication on VM**
```bash
ssh odoo@odoo-vm  # if you can login
sudo nano /etc/ssh/sshd_config

# Find and set:
PasswordAuthentication yes

# Restart SSH
sudo systemctl restart sshd
```

**Solution 4: Use SSH key instead**
```bash
ssh-keygen -t rsa
ssh-copy-id odoo@odoo-vm
```

---

### ❌ "Connection refused"

**Symptoms:**
```bash
ssh: connect to host odoo-vm port 22: Connection refused
```

**Causes:**
1. VM is not running
2. SSH service not running on VM
3. Wrong IP in /etc/hosts

**Solutions:**

**Solution 1: Check VM is running**
```bash
# VirtualBox Manager → Check VM status
# Or
ping odoo-vm
```

**Solution 2: Start SSH service on VM**
```bash
# Login via VirtualBox console
sudo systemctl start sshd
sudo systemctl enable sshd
```

**Solution 3: Verify IP address**
```bash
# On VM (via VirtualBox console)
ip addr show | grep "inet " | grep -v 127.0.0.1

# Update /etc/hosts on host with correct IP
```

---

### ❌ "No route to host"

**Symptoms:**
```bash
ssh: connect to host odoo-vm port 22: No route to host
```

**Causes:**
1. Network adapter not in Bridged mode
2. VM network not started
3. Firewall blocking connection

**Solutions:**

**Solution 1: Check VirtualBox network settings**
```
VirtualBox → VM → Settings → Network → Adapter 1
- Attached to: Bridged Adapter ✓
- Cable Connected: ✓
```

**Solution 2: Restart VM networking**
```bash
# On VM (via VirtualBox console)
sudo systemctl restart systemd-networkd
sudo netplan apply
```

**Solution 3: Check host firewall**
```bash
# On host machine
sudo ufw status
# If active, allow SSH
sudo ufw allow from 192.168.1.0/24
```

---

## Network Problems

### ❌ "Network unreachable" after setup-static-ip.sh

**Symptoms:**
- Lost connection to VM after running setup script
- Cannot ping VM

**Causes:**
1. Wrong gateway configured
2. Wrong network interface name
3. Network configuration error

**Solutions:**

**Solution 1: Access via VirtualBox console**
```
VirtualBox → VM → Show → Console
Login: odoo
Password: 1234
```

**Solution 2: Check network configuration**
```bash
# On VM console
ip addr show
ip route

# Should see:
# default via 192.168.1.1 dev enp0s3
# 192.168.1.0/24 dev enp0s3 ... src 192.168.1.101
```

**Solution 3: Restore from backup**
```bash
# On VM console
sudo cp /root/netplan-backup-*/50-cloud-init.yaml /etc/netplan/
sudo rm /etc/netplan/01-static-ip.yaml
sudo netplan apply
```

**Solution 4: Re-run setup script**
```bash
sudo ./setup-static-ip.sh
```

---

### ❌ IP changes after VM restart

**Symptoms:**
- IP was .101, now it's different
- Cannot connect after restart

**Causes:**
1. Static IP not configured (still using DHCP)
2. netplan configuration overridden

**Solutions:**

**Solution 1: Verify static IP configuration**
```bash
cat /etc/netplan/01-static-ip.yaml
# Should show: addresses: - 192.168.X.101/24
```

**Solution 2: Check netplan files**
```bash
ls /etc/netplan/
# Should have: 01-static-ip.yaml
# Should NOT have: 50-cloud-init.yaml (should be .disabled)
```

**Solution 3: Re-apply netplan**
```bash
sudo netplan apply
```

---

## Odoo Startup Issues

### ❌ "Address already in use"

**Symptoms:**
```bash
OSError: [Errno 98] Address already in use
```

**Causes:**
- Another Odoo process already running
- Port 8069 occupied by another service

**Solutions:**

**Solution 1: Let the script handle it**
The `run.sh` script should automatically stop old processes. If it doesn't:

```bash
ssh odoo@odoo-vm
pkill -f odoo-bin
exit

# Try again
python odoo-restart.py -d swisscapital --dev xml
```

**Solution 2: Kill processes manually**
```bash
ssh odoo@odoo-vm
ps aux | grep odoo-bin
# Find PID (e.g., 1234)
kill -9 1234
exit
```

**Solution 3: Check for other services on port 8069**
```bash
ssh odoo@odoo-vm
sudo lsof -i :8069
# If another service is using it, stop it
```

---

### ❌ "Database 'swisscapital' does not exist"

**Symptoms:**
```bash
psycopg2.OperationalError: FATAL: database "swisscapital" does not exist
```

**Causes:**
- Database not created
- Wrong database name

**Solutions:**

**Solution 1: List available databases**
```bash
ssh odoo@odoo-vm
psql -U odoo -l
# Lists all databases
```

**Solution 2: Use correct database name**
```bash
python odoo-restart.py -d correct_db_name --dev xml
```

**Solution 3: Create database**
```bash
# Via Odoo web interface
http://odoo-vm:8069/web/database/manager
```

---

### ❌ "ImportError: No module named odoo"

**Symptoms:**
```bash
ImportError: No module named odoo
```

**Causes:**
- Not using virtual environment
- Wrong Python path in run.sh

**Solutions:**

**Solution 1: Verify Python path in run.sh**
```bash
ssh odoo@odoo-vm
cat ~/run.sh | grep PYTHON

# Should be:
PYTHON="/home/odoo/.venv/bin/python3.7"
```

**Solution 2: Check virtual environment exists**
```bash
ssh odoo@odoo-vm
ls -la /home/odoo/.venv/bin/python3.7
# Should exist
```

**Solution 3: Activate venv and test**
```bash
ssh odoo@odoo-vm
source /home/odoo/.venv/bin/activate
python -c "import odoo; print(odoo.__version__)"
# Should print: 11.0
```

---

### ❌ "Could not create the logfile directory"

**Symptoms:**
```bash
ERROR: couldn't create the logfile directory. Logging to the standard output.
```

**Causes:**
- Log directory doesn't exist or no permissions

**Solutions:**

**Solution 1: Create log directory**
```bash
ssh odoo@odoo-vm
sudo mkdir -p /var/log/odoo
sudo chown odoo:odoo /var/log/odoo
```

**Solution 2: Update odoo.conf**
```bash
ssh odoo@odoo-vm
nano /mnt/odoo11/conf/odoo_vb.conf

# Change or comment out:
# logfile = /var/log/odoo/odoo.log
logfile = False  # Logs to stdout instead
```

**Note:** This is usually just a warning and doesn't prevent Odoo from running.

---

## Process Management

### ❌ Ctrl+C doesn't stop Odoo on VM

**Symptoms:**
- Press Ctrl+C in terminal
- Odoo keeps running on VM
- Need to manually kill processes

**Causes:**
- Bug in exception handling
- SSH connection dropped

**Solutions:**

**Solution 1: Check script is updated**
```python
# In odoo-restart.py, should have:
except KeyboardInterrupt:
    print("\n⚠️  Interrupted by user (Ctrl+C)")
    print("🛑 Stopping Odoo on VirtualBox...")
    
    stop_cmd = [
        "sshpass", "-p", PASSWORD,
        "ssh", "-o", "StrictHostKeyChecking=no", f"{USER}@{HOST}",
        "bash", "-c", 
        "pkill -f 'python.*odoo-bin'; pkill -f 'bash.*run.sh'"
    ]
```

**Solution 2: Manual stop**
```bash
ssh odoo@odoo-vm "pkill -f odoo-bin"
```

**Solution 3: Create stop script**
```bash
# Create odoo-stop.py
python -c "import subprocess; subprocess.run(['ssh', 'odoo@odoo-vm', 'pkill -f odoo-bin'])"
```

---

### ❌ Multiple Odoo processes running

**Symptoms:**
```bash
ps aux | grep odoo-bin
# Shows multiple processes
```

**Causes:**
- Previous processes didn't stop properly
- Multiple users started Odoo

**Solutions:**

**Solution 1: Kill all Odoo processes**
```bash
ssh odoo@odoo-vm
pkill -9 -f odoo-bin
ps aux | grep odoo-bin  # Verify all stopped
```

**Solution 2: Reboot VM**
```bash
ssh odoo@odoo-vm
sudo reboot
```

---

## Performance Issues

### ❌ Odoo is very slow

**Symptoms:**
- Odoo takes long to start
- Web interface is sluggish
- High CPU usage

**Causes:**
1. Insufficient VM resources
2. Too many workers
3. Debug mode overhead

**Solutions:**

**Solution 1: Increase VM resources**
```
VirtualBox → VM → Settings
- System → Base Memory: 4096 MB (minimum)
- System → Processors: 2 CPUs
```

**Solution 2: Check workers configuration**
```bash
ssh odoo@odoo-vm
nano /mnt/odoo11/conf/odoo_vb.conf

# For development, use:
workers = 0  # Single-threaded mode
```

**Solution 3: Disable unnecessary dev modes**
```bash
# Use minimal dev mode
python odoo-restart.py -d swisscapital --dev xml

# Instead of:
python odoo-restart.py -d swisscapital --dev all
```

---

### ❌ Logs are too verbose

**Symptoms:**
- Terminal flooded with messages
- Hard to read relevant info

**Solutions:**

**Solution 1: Filter logs**
```bash
python odoo-restart.py -d swisscapital --dev xml | grep -E "(ERROR|WARNING|INFO)"
```

**Solution 2: Configure log level in odoo.conf**
```bash
ssh odoo@odoo-vm
nano /mnt/odoo11/conf/odoo_vb.conf

# Set log level
log_level = info  # or: warn, error
```

---

## VirtualBox Issues

### ❌ "VBoxManage: error: Could not find a controller"

**Symptoms:**
- VM won't start
- VirtualBox errors

**Solutions:**

**Solution 1: Check VM integrity**
```bash
VBoxManage showvminfo "VM_NAME" | grep State
```

**Solution 2: Re-import VM**
```
File → Import Appliance → Select .ova file
```

---

### ❌ Shared folders not working

**Symptoms:**
- Cannot access /mnt/odoo11 or similar paths

**Solutions:**

**Solution 1: Install Guest Additions**
```bash
# In VM
sudo apt update
sudo apt install virtualbox-guest-utils virtualbox-guest-dkms
sudo reboot
```

**Solution 2: Check mount points**
```bash
ssh odoo@odoo-vm
df -h | grep vbox
mount | grep vbox
```

---

## Script-Specific Issues

### ❌ "ModuleNotFoundError: No module named 'sshpass'"

**Symptoms:**
```bash
ModuleNotFoundError: No module named 'sshpass'
```

**Causes:**
- Misunderstanding: `sshpass` is not a Python module

**Solutions:**

`sshpass` is a system command, not Python module:

```bash
# Install system package
sudo apt install sshpass

# Verify
which sshpass
sshpass -V
```

---

### ❌ "bash: run.sh: command not found"

**Symptoms:**
```bash
bash: /home/odoo/run.sh: No such file or directory
```

**Causes:**
- run.sh not uploaded to VM
- Wrong path in Python script

**Solutions:**

**Solution 1: Upload run.sh**
```bash
scp vm-setup/run.sh odoo@odoo-vm:/home/odoo/
ssh odoo@odoo-vm "chmod +x ~/run.sh"
```

**Solution 2: Verify path**
```bash
ssh odoo@odoo-vm "ls -l ~/run.sh"
# Should show: -rwxr-xr-x 1 odoo odoo ... run.sh
```

**Solution 3: Check REMOTE_SCRIPT variable**
```python
# In odoo-restart.py
REMOTE_SCRIPT = "/home/odoo/run.sh"  # Correct path
```

---

## Getting Help

If your issue is not listed here:

1. **Check the logs:**
```bash
# On VM
ssh odoo@odoo-vm
tail -f /var/log/odoo/odoo.log
# or
journalctl -u odoo -f
```

2. **Enable debug output:**
```bash
# In odoo-restart.py, add after imports:
import logging
logging.basicConfig(level=logging.DEBUG)
```

3. **Create GitHub Issue:**
   - Go to: https://github.com/YOUR_USERNAME/odoo-virtualbox-manager/issues
   - Include:
     - Full error message
     - Output of `python odoo-restart.py -d swisscapital --dev xml`
     - VM OS version (`lsb_release -a`)
     - Host OS version

---

## Debug Checklist

Before asking for help, verify:

- [ ] VM is running in VirtualBox
- [ ] VM has network connectivity (`ping 8.8.8.8`)
- [ ] Can ping VM from host (`ping odoo-vm`)
- [ ] Can SSH manually (`ssh odoo@odoo-vm`)
- [ ] sshpass is installed (`which sshpass`)
- [ ] /etc/hosts has correct IP
- [ ] run.sh exists on VM and is executable
- [ ] Python script has correct password
- [ ] No Odoo processes running (`ps aux | grep odoo-bin`)

---

**Still having issues? Open an issue on GitHub!** 🐛