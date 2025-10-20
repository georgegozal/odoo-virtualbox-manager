#!/usr/bin/env python3
"""
Odoo VirtualBox Manager - Windows Edition
Works on Windows 10/11 with Python 3.7+
"""
import subprocess
import sys
import os
import platform

# SSH კონფიგურაცია
HOST = "odoo-vm"  # VirtualBox-ის hostname (ან 192.168.1.101)
USER = "odoo"
SSH_KEY = os.path.expanduser("~/.ssh/id_rsa")  # SSH key path
REMOTE_SCRIPT = "/home/odoo/run.sh"

def check_requirements():
    """Check if required tools are installed"""
    
    # Check Python version
    if sys.version_info < (3, 7):
        print("❌ Python 3.7 or higher is required")
        print(f"   Current version: {sys.version}")
        sys.exit(1)
    
    # Check if ssh is available
    try:
        subprocess.run(["ssh", "-V"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ SSH client not found!")
        print("   Please install OpenSSH Client:")
        print("   Settings → Apps → Optional Features → Add OpenSSH Client")
        sys.exit(1)
    
    # Check if SSH key exists
    if not os.path.exists(SSH_KEY):
        print("⚠️  SSH key not found!")
        print(f"   Expected location: {SSH_KEY}")
        print("")
        print("📝 To setup SSH key, run:")
        print("   setup-ssh-keys.bat")
        print("")
        response = input("Continue anyway? (y/n): ").lower()
        if response != 'y':
            sys.exit(0)

def main():
    print("🪟 Odoo VirtualBox Manager (Windows Edition)")
    print("=" * 50)
    print("")
    
    # Check requirements
    check_requirements()
    
    print("📋 Arguments received:", sys.argv)
    args = sys.argv[1:]
    
    # SSH command with key authentication
    cmd = [
        "ssh",
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=NUL",  # Windows equivalent of /dev/null
        "-i", SSH_KEY,
        f"{USER}@{HOST}",
        "bash", REMOTE_SCRIPT
    ]
    cmd.extend(args)
    
    print("🚀 Executing command:")
    # Show command without key path
    safe_cmd = [
        "ssh", "-o", "StrictHostKeyChecking=no",
        f"{USER}@{HOST}", "bash", REMOTE_SCRIPT
    ] + args
    print(" ".join(safe_cmd))
    print("")
    
    # Execute SSH command
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        encoding='utf-8',
        errors='replace'  # Handle encoding errors gracefully
    )
    
    try:
        for line in proc.stdout:
            print(line, end="")
            sys.stdout.flush()
    except KeyboardInterrupt:
        print("\n⚠️  Interrupted by user (Ctrl+C)")
        print("🛑 Stopping Odoo on VirtualBox...")
        
        # Stop Odoo on VM
        stop_cmd = [
            "ssh",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=NUL",
            "-i", SSH_KEY,
            f"{USER}@{HOST}",
            "bash", "-c",
            "pkill -f 'python.*odoo-bin'; pkill -f 'bash.*run.sh'"
        ]
        
        result = subprocess.run(stop_cmd, capture_output=True, text=True)
        
        if result.returncode == 0 or result.returncode == 1:
            print("✅ Odoo stopped on VirtualBox")
        else:
            print(f"⚠️  Stop command returned: {result.returncode}")
            if result.stderr:
                print(f"   Error: {result.stderr.strip()}")
    finally:
        proc.terminate()
        proc.wait()
    
    return proc.returncode

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\n📞 For help, check: https://github.com/YOUR_USERNAME/odoo-virtualbox-manager")
        sys.exit(1)
