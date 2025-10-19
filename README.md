# 🚀 Odoo VirtualBox Manager

**Seamlessly run and manage Odoo in VirtualBox from your host machine with a single Python script.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)
[![Odoo 11](https://img.shields.io/badge/Odoo-11.0-purple.svg)](https://www.odoo.com/)

---

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Documentation](#-documentation)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

- 🎮 **Single Command Control** - Start/stop Odoo in VirtualBox from your host machine
- 🔄 **Smart Process Management** - Automatically stops existing Odoo processes before starting
- 📡 **Network Auto-Detection** - Works with any network (192.168.1.x, 192.168.100.x, etc.)
- 🎯 **Static IP Setup** - One-time script automatically configures .101 IP on any network
- 🖥️ **IDE Integration** - Perfect for PyCharm/VS Code with Run/Stop buttons
- 📊 **Real-time Logs** - See Odoo logs streaming live in your terminal
- ⚡ **Fast Development** - No need to SSH manually - everything from one script
- 🔧 **Module Updates** - Update modules with simple flags: `-u sale,stock`
- 🌍 **Universal** - Share VM with team members, works on any network automatically

---

## ⚡ Quick Start

### On VirtualBox VM (One-time setup):
```bash
# Run the network setup script (automatically detects your network)
sudo ./setup-static-ip.sh
```

### On Host Machine:
```bash
# Add to /etc/hosts
echo "192.168.X.101    odoo-vm" | sudo tee -a /etc/hosts

# Start Odoo
python odoo-restart.py -d swisscapital --dev xml

# Stop Odoo (Ctrl+C or PyCharm Stop button)
```

**That's it!** 🎉

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│     Host Machine (Your Laptop)      │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   odoo-restart.py           │   │
│  │   - Manages SSH connection  │   │
│  │   - Streams logs            │   │
│  │   - Handles stop/restart    │   │
│  └─────────────┬───────────────┘   │
│                │ SSH                │
│                │ (sshpass)          │
└────────────────┼───────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│   VirtualBox VM (Ubuntu Server)     │
│   IP: 192.168.X.101 (auto-detected) │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   run.sh                    │   │
│  │   - Stops old processes     │   │
│  │   - Starts Odoo             │   │
│  │   - Handles parameters      │   │
│  └─────────────┬───────────────┘   │
│                │                    │
│                ▼                    │
│  ┌─────────────────────────────┐   │
│  │   Odoo 11 (Python 3.7)      │   │
│  │   - Database: swisscapital  │   │
│  │   - Dev mode: xml           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 📥 Installation

### Prerequisites

**Host Machine:**
- Python 3.7+
- `sshpass` installed: `sudo apt install sshpass`

**VirtualBox VM:**
- Ubuntu Server 22.04/24.04
- Odoo 11 installed
- Network Adapter: Bridged

### Setup Steps

1. **Clone Repository**
```bash
git clone https://github.com/YOUR_USERNAME/odoo-virtualbox-manager.git
cd odoo-virtualbox-manager
```

2. **VM Setup (One-time)**
```bash
# Copy files to VM
scp vm-setup/setup-static-ip.sh odoo@YOUR_VM_IP:/home/odoo/
scp vm-setup/run.sh odoo@YOUR_VM_IP:/home/odoo/

# SSH into VM
ssh odoo@YOUR_VM_IP

# Make scripts executable
chmod +x ~/setup-static-ip.sh ~/run.sh

# Run network setup
sudo ./setup-static-ip.sh
```

3. **Host Machine Setup**
```bash
# Add VM hostname to /etc/hosts
# The setup script will tell you the exact IP
echo "192.168.X.101    odoo-vm" | sudo tee -a /etc/hosts

# Test connection
ping odoo-vm
ssh odoo@odoo-vm
```

4. **Configure Python Script**
```bash
cd scripts/
nano odoo-restart.py

# Update these lines:
HOST = "odoo-vm"
PASSWORD = "your_password"
```

---

## 🎮 Usage

### Basic Commands

```bash
# Start Odoo (default database)
python odoo-restart.py -d swisscapital --dev xml

# Update modules
python odoo-restart.py -d swisscapital -u sale,stock --dev xml

# Different dev mode
python odoo-restart.py -d swisscapital --dev all

# Stop Odoo
# Press Ctrl+C or use PyCharm/VS Code Stop button
```

### PyCharm Integration

1. **Create Run Configuration:**
   - `Run → Edit Configurations → + → Python`
   - Name: `Odoo VirtualBox Start`
   - Script: `scripts/odoo-restart.py`
   - Parameters: `-d swisscapital --dev xml`

2. **Use Run/Stop Buttons:**
   - ▶️ **Run** - Starts Odoo
   - ⏹️ **Stop** - Stops Odoo on VirtualBox

### Command Line Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `-d DATABASE` | Database name | `-d swisscapital` |
| `--dev MODE` | Developer mode | `--dev xml` / `--dev all` |
| `-u MODULES` | Update modules | `-u sale,stock` |

---

## ⚙️ Configuration

### Python Script (odoo-restart.py)

```python
# SSH Configuration
HOST = "odoo-vm"              # VM hostname
USER = "odoo"                 # SSH user
PASSWORD = "1234"             # SSH password
REMOTE_SCRIPT = "/home/odoo/run.sh"
```

### Bash Script (run.sh)

```bash
# Odoo Paths
ODOO_DIR="/mnt/odoo11/odoo"
CONF_FILE="/mnt/odoo11/conf/odoo_vb.conf"
PYTHON="/home/odoo/.venv/bin/python3.7"

# Defaults
DEFAULT_DB="swisscapital"
```

---

## 📚 Documentation

Detailed documentation available in [`docs/`](docs/) directory:

- [**Installation Guide**](docs/INSTALLATION.md) - Complete setup instructions
- [**Configuration Guide**](docs/CONFIGURATION.md) - All configuration options
- [**Network Setup**](docs/NETWORK-SETUP.md) - Network configuration details
- [**Troubleshooting**](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [**Debug Guide**](docs/DEBUG-GUIDE.md) - Remote debugging setup *(coming soon)*

---

## 🔧 Troubleshooting

### Common Issues

**Problem: "Permission denied (publickey,password)"**
```bash
# Solution: Check password in odoo-restart.py
# Or use SSH key: ssh-copy-id odoo@odoo-vm
```

**Problem: "Address already in use"**
```bash
# Solution: Old Odoo process running
ssh odoo@odoo-vm
pkill -f odoo-bin
```

**Problem: "Connection refused"**
```bash
# Solution: Check VM is running and IP is correct
ping odoo-vm
ssh odoo@odoo-vm
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more solutions.

---

## 🌐 Network Examples

The `setup-static-ip.sh` script works with **any network**:

| Your Router | VM Gets | Add to /etc/hosts |
|-------------|---------|-------------------|
| 192.168.1.1 | 192.168.1.101 | `192.168.1.101 odoo-vm` |
| 192.168.100.1 | 192.168.100.101 | `192.168.100.101 odoo-vm` |
| 10.0.0.1 | 10.0.0.101 | `10.0.0.101 odoo-vm` |

**Always ends with .101** - easy to remember! 🎯

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**George** - Initial work

---

## 🙏 Acknowledgments

- Built for Odoo 11 development teams
- Designed for seamless VirtualBox workflow
- Optimized for PyCharm/VS Code integration

---

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Review [existing issues](https://github.com/YOUR_USERNAME/odoo-virtualbox-manager/issues)
3. Create a [new issue](https://github.com/YOUR_USERNAME/odoo-virtualbox-manager/issues/new)

---

**Made with ❤️ for Odoo developers who love automation**