# Odoo 11 VirtualBox VM - Setup Instructions

## 📦 VM Information
- **OS:** Ubuntu Server 22.04/24.04
- **Username:** odoo
- **Password:** 1234
- **Odoo Version:** 11.0
- **Python:** 3.7

---

## 🚀 First Time Setup (ONE TIME ONLY)

### Step 1: Start VirtualBox VM
```
VirtualBox → Select VM → Start
```

or you can run in headless mode and then use ssh to connect

```
VBoxManage startvm "Ubuntu Server" --type headless
```

### Step 2: Login via Console
```
Username: odoo
Password: 1234
```

### Step 3: Run Static IP Setup
```bash
sudo ./setup-static-ip.sh
```

**Follow the prompts:**
- The script will detect your network automatically
- It will assign IP: `YOUR_NETWORK.101` (e.g., 192.168.1.101)
- Press `y` to confirm

### Step 4: Note Your New IP
After setup completes, you'll see:
```
📌 Your new static IP address is: 192.168.X.101
```

**Write this down!** 📝

---

## 🖥️ Connect from Host Machine

### Step 5: Add to /etc/hosts (Host Machine)
```bash
# On your host machine (not VM)
sudo nano /etc/hosts

# Add this line (replace X with your network):
192.168.X.101    odoo-vm
```

### Step 6: Test SSH Connection
```bash
ssh odoo@odoo-vm
```

---

## 🐍 Python Script Setup (Host Machine)

### Step 7: Update odoo-restart.py
```python
HOST = "odoo-vm"  # or use 192.168.X.101 directly
USER = "odoo"
PASSWORD = "1234"
```

### Step 8: Run Odoo
```bash
python odoo-restart.py -d swisscapital --dev xml
```

---

## 🔧 Troubleshooting

### Problem: "Connection refused" or "No route to host"
**Solution:** 
1. Check VM is running: `VirtualBox → VM → Show`
2. Verify IP: `ssh odoo@192.168.X.101` (use actual IP)
3. Check /etc/hosts has correct IP

### Problem: "Address already in use"
**Solution:** Odoo is already running
```bash
ssh odoo@odoo-vm
pkill -f odoo-bin
```

### Problem: Lost IP after restart
**Solution:** Static IP is configured, just reconnect with same IP

---

## 📂 Important Files in VM

- `/home/odoo/run.sh` - Odoo start script
- `/home/odoo/setup-static-ip.sh` - IP setup script
- `/mnt/odoo11/odoo/` - Odoo source code
- `/mnt/odoo11/conf/odoo_vb.conf` - Odoo configuration

---

## 🎓 Usage Examples

### Start Odoo (normal mode)
```bash
python odoo-restart.py -d swisscapital --dev xml
```

### Start with module update
```bash
python odoo-restart.py -d swisscapital -u sale,stock --dev xml
```

### Stop Odoo
Press `Ctrl+C` in terminal or use PyCharm Stop button

---

## 💡 Network Examples

| Your Router | VM Will Get | Add to /etc/hosts |
|-------------|-------------|-------------------|
| 192.168.1.1 | 192.168.1.101 | 192.168.1.101 odoo-vm |
| 192.168.100.1 | 192.168.100.101 | 192.168.100.101 odoo-vm |
| 10.0.0.1 | 10.0.0.101 | 10.0.0.101 odoo-vm |

---

## 📞 Support
If you have issues, check:
1. VirtualBox VM is running
2. Network adapter is set to "Bridged Adapter"
3. Static IP setup completed successfully
4. /etc/hosts on host machine is correct

---

**Created by:** George@development
**Date:** 2025