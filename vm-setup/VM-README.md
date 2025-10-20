# 📦 Detailed VM Setup Information

Complete information about the Odoo VirtualBox VM contents and configuration.

---

## 📋 Table of Contents

1. [VM Specifications](#vm-specifications)
2. [Installed Software](#installed-software)
3. [Directory Structure](#directory-structure)
4. [Services](#services)
5. [Network Configuration](#network-configuration)
6. [Database Setup](#database-setup)
7. [OpenVPN Configuration](#openvpn-configuration)
8. [Security](#security)

---

## VM Specifications

### System Information

- **Operating System:** Ubuntu Server 22.04 LTS
- **Hostname:** odoo-vm
- **Username:** odoo
- **Password:** 1234 (⚠️ Change in production!)
- **RAM:** 4GB (recommended minimum)
- **CPU:** 2 cores (recommended minimum)
- **Disk:** 50GB (dynamically allocated)

---

## Installed Software

### Core Components

| Software | Version | Purpose |
|----------|---------|---------|
| **Python** | 3.7 | Odoo runtime |
| **PostgreSQL** | 15 | Database server |
| **Odoo** | 11.0 | ERP system |
| **OpenVPN** | 2.5+ | VPN connectivity |
| **OpenSSH** | Latest | Remote access |
| **Git** | Latest | Version control |

### Python Virtual Environment

Location: `/home/odoo/.venv`

```bash
# Activate venv
source /home/odoo/.venv/bin/activate

# Check Python version
python --version
# Python 3.7.x

# Check installed packages
pip list
```

---

## Directory Structure

```
/home/odoo/
├── .venv/                    # Python virtual environment
├── run.sh                    # Odoo start script
├── setup-static-ip.sh        # Network configuration script
└── README.md                 # Quick reference

/mnt/odoo11/
├── odoo/                     # Odoo source code
│   ├── addons/              # Standard Odoo modules
│   ├── odoo/                # Core Odoo framework
│   └── odoo-bin             # Odoo executable
├── conf/
│   ├── odoo_vb.conf         # Main configuration (default)
│   ├── production.conf      # Production settings (optional)
│   └── test.conf            # Test environment (optional)
├── swisscapital/            # Custom modules
│   └── [custom addons]
└── logs/
    └── odoo.log             # Odoo log files

/var/log/odoo/               # System log directory (if configured)

/etc/openvpn/                # OpenVPN configuration
├── client/
│   └── client.ovpn          # VPN client config
└── server/                  # Server configs (if applicable)
```

---

## Services

### Systemd Services

The VM uses manual script control by default, but can be configured with systemd.

#### Check Service Status

```bash
# SSH
sudo systemctl status sshd

# PostgreSQL
sudo systemctl status postgresql

# OpenVPN (if configured)
sudo systemctl status openvpn@client
```

---

## Network Configuration

### Default Network Settings

**Interface:** enp0s3 (or eth0)  
**Mode:** Bridged Adapter  
**DHCP:** Disabled (after setup)  
**Static IP:** x.x.x.101 (auto-detected network)

### Netplan Configuration

Location: `/etc/netplan/01-static-ip.yaml`

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.1.101/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

### Ports

| Port | Service | Purpose |
|------|---------|---------|
| 22 | SSH | Remote access |
| 8069 | Odoo HTTP | Web interface |
| 5432 | PostgreSQL | Database (localhost only) |
| 1194 | OpenVPN | VPN connection (if enabled) |

---

## Database Setup

### PostgreSQL Configuration

**Location:** `/etc/postgresql/15/main/postgresql.conf`

#### Default Settings

```ini
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
```

### Database Users

| User | Password | Purpose |
|------|----------|---------|
| postgres | postgres | Superuser |
| odoo | odoo | Odoo application |

### Default Databases

- `swisscapital` - Main development database
- `postgres` - System database
- `template1` - Template database

### Database Management

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# List databases
\l

# Connect to database
\c swisscapital

# List tables
\dt

# Exit
\q
```

### Backup Database

```bash
# Backup
sudo -u postgres pg_dump swisscapital > backup.sql

# Restore
sudo -u postgres psql swisscapital < backup.sql
```

---

## OpenVPN Configuration

### Pre-configured VPN

The VM comes with OpenVPN pre-configured and ready to use.

**No manual configuration needed!**

### VPN Control Commands

Use the `swiss` command to control VPN:

```bash
# Connect to VPN
swiss -c

# Disconnect from VPN
swiss -d
```

### Check VPN Status

```bash
# Check if VPN service is running
sudo systemctl status openvpn@client

# View VPN logs
sudo journalctl -u openvpn@client -f

# Check VPN interface
ip addr show tun0

# Verify external IP (should show VPN IP when connected)
curl ifconfig.me
```

### VPN Configuration Files

**Location:** `/etc/openvpn/client/`

**Note:** Configuration files are already set up. Do not modify unless necessary.

### Troubleshooting VPN

```bash
# Restart VPN service
sudo systemctl restart openvpn@client

# Check VPN connection logs
sudo tail -f /var/log/openvpn/client.log

# Test connection
ping 8.8.8.8
```

### VPN Auto-start (Optional)

To enable VPN auto-start on boot:

```bash
sudo systemctl enable openvpn@client
```

To disable auto-start:

```bash
sudo systemctl disable openvpn@client
```

---

## Security

### Firewall (UFW)

```bash
# Check status
sudo ufw status

# Allow SSH
sudo ufw allow 22/tcp

# Allow Odoo
sudo ufw allow 8069/tcp

# Enable firewall
sudo ufw enable
```

### SSH Configuration

**Location:** `/etc/ssh/sshd_config`

```ini
# Recommended settings
PermitRootLogin no
PasswordAuthentication yes  # Can be set to 'no' after SSH keys
PubkeyAuthentication yes
```

### Change Default Password

```bash
# Change odoo user password
passwd

# Enter new password (twice)
```

---

## Odoo Configuration Files

### Main Configuration (odoo_vb.conf)

**Location:** `/mnt/odoo11/conf/odoo_vb.conf`

```ini
[options]
admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo
db_name = swisscapital

addons_path = /mnt/odoo11/odoo/addons,/mnt/odoo11/odoo/odoo/addons,/mnt/odoo11/swisscapital

http_port = 8069
workers = 0  # 0 = single-threaded (development)

logfile = /var/log/odoo/odoo.log
log_level = info

# Development settings
dev_mode = True
```

### Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `db_name` | swisscapital | Default database |
| `http_port` | 8069 | Web interface port |
| `workers` | 0 | Number of worker processes (0 = dev mode) |
| `log_level` | info | Logging verbosity |
| `dev_mode` | True | Enable developer features |

---

## Maintenance Tasks

### Update Odoo Source Code

```bash
cd /mnt/odoo11/odoo
git pull origin 11.0
```

### Update Python Packages

```bash
source /home/odoo/.venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Clean Odoo Cache

```bash
# Stop Odoo first
pkill -f odoo-bin

# Remove cache
rm -rf ~/.local/share/Odoo/sessions/*
rm -rf /tmp/oe-sessions-*
```

### Check Disk Space

```bash
df -h
du -sh /mnt/odoo11/*
```

---

## Performance Tuning

### PostgreSQL Tuning

Edit `/etc/postgresql/15/main/postgresql.conf`:

```ini
# For 4GB RAM VM
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
work_mem = 10MB
min_wal_size = 1GB
max_wal_size = 4GB
```

Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```

### Odoo Worker Configuration

For production (edit `odoo_vb.conf`):

```ini
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560  # 2.5GB
limit_memory_soft = 2147483648  # 2GB
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
```

---

## Backup & Restore

### Full VM Backup

**Export VM:**
```
VirtualBox → File → Export Appliance → Select VM
Format: OVF 1.0
Include ISO image paths: No
Write Manifest file: Yes
```

### Database Backup Script

Create `/home/odoo/backup-db.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/home/odoo/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="swisscapital"

mkdir -p "$BACKUP_DIR"
sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz"
echo "Backup created: $BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz"

# Keep only last 7 backups
ls -t "$BACKUP_DIR"/*.sql.gz | tail -n +8 | xargs rm -f
```

Make executable:
```bash
chmod +x /home/odoo/backup-db.sh
```

Run backup:
```bash
./backup-db.sh
```

---

## Troubleshooting

### View Logs

```bash
# Odoo logs (if running via script)
tail -f /var/log/odoo/odoo.log

# System logs
sudo journalctl -u postgresql -f
sudo journalctl -u sshd -f

# Check all Odoo processes
ps aux | grep odoo
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -U odoo -d swisscapital -h localhost

# Check PostgreSQL is running
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Port Already in Use

```bash
# Find what's using port 8069
sudo lsof -i :8069

# Kill process
sudo kill -9 <PID>
```

### Network Issues

```bash
# Check network interface
ip addr show

# Check routing
ip route

# Test DNS
nslookup google.com

# Restart networking
sudo netplan apply
```

---

## Customization

### Add Custom Modules

1. **Copy module to:**
   ```
   /mnt/odoo11/swisscapital/your_module/
   ```

2. **Update addons_path in conf:**
   ```ini
   addons_path = /mnt/odoo11/odoo/addons,...,/mnt/odoo11/swisscapital
   ```

3. **Restart Odoo with update:**
   ```bash
   ./run.sh -d swisscapital -u your_module --dev xml
   ```

### Change Database

Edit `/mnt/odoo11/conf/odoo_vb.conf`:

```ini
db_name = your_database_name
```

Or specify at runtime:
```bash
./run.sh -d your_database_name --dev xml
```

---

## VM Cloning

### Before Cloning

1. **Stop all services:**
   ```bash
   pkill -f odoo-bin
   sudo systemctl stop postgresql
   ```

2. **Clean up:**
   ```bash
   # Remove logs
   sudo rm -f /var/log/odoo/*.log
   
   # Remove SSH host keys (will regenerate)
   sudo rm /etc/ssh/ssh_host_*
   
   # Clear bash history
   history -c
   ```

3. **Export VM** from VirtualBox

### After Cloning

On the cloned VM:

1. **Regenerate SSH keys:**
   ```bash
   sudo dpkg-reconfigure openssh-server
   ```

2. **Run static IP setup:**
   ```bash
   sudo ./setup-static-ip.sh
   ```

3. **Change passwords:**
   ```bash
   passwd  # Change odoo user password
   sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'new_password';"
   ```

---

## System Updates

### Update Ubuntu

```bash
# Update package list
sudo apt update

# Upgrade packages
sudo apt upgrade -y

# Remove old packages
sudo apt autoremove -y

# Reboot if needed
sudo reboot
```

### Check System Info

```bash
# OS version
lsb_release -a

# Kernel version
uname -r

# System resources
free -h
df -h
```

---

## Support & Contacts

### Log Files Locations

- **Odoo:** `/var/log/odoo/odoo.log`
- **PostgreSQL:** `/var/log/postgresql/postgresql-15-main.log`
- **System:** `/var/log/syslog`
- **SSH:** `/var/log/auth.log`

### Useful Commands

```bash
# Check all running services
sudo systemctl list-units --type=service --state=running

# View system resource usage
htop

# Check network connections
sudo netstat -tulpn

# View disk usage by directory
du -h --max-depth=1 /mnt/odoo11/
```

---

## Quick Reference Card

### Common Tasks

| Task | Command |
|------|---------|
| Start Odoo | `./run.sh -d swisscapital --dev xml` |
| Stop Odoo | `pkill -f odoo-bin` |
| Check IP | `ip addr show` |
| Backup DB | `./backup-db.sh` |
| View logs | `tail -f /var/log/odoo/odoo.log` |
| SSH from host | `ssh odoo@odoo-vm` |
| Start VPN | `sudo systemctl start openvpn@client` |

---

**VM Version:** 1.0  
**Last Updated:** 2025  
**Maintained by:** George@development