#!/usr/bin/env python3
"""
Odoo Remote Runner - SSH Key Authentication
Stream logs in real-time, proper Ctrl+C handling, PyCharm debug support
"""
import subprocess
import sys
import signal
import os
import time

# ==================== კონფიგურაცია ====================
HOST = "odoo-vm"
USER = "odoo"
REMOTE_SCRIPT = "/home/odoo/run.sh"

# Global process reference
ssh_process = None
cleanup_done = False


def cleanup_remote_odoo():
    """აჩერებს Odoo-ს VM-ზე"""
    global cleanup_done
    if cleanup_done:
        return
    cleanup_done = True
    
    print("\n🛑 Stopping Odoo on VM...", flush=True)
    
    stop_cmd = [
        "ssh", f"{USER}@{HOST}",
        "pkill -TERM -f odoo-bin || true"
    ]
    
    try:
        subprocess.run(stop_cmd, capture_output=True, timeout=5)
        print("✅ Odoo stopped", flush=True)
    except Exception as e:
        print(f"⚠️  Could not stop Odoo: {e}", flush=True)
    
    # Kill local SSH process
    global ssh_process
    if ssh_process and ssh_process.poll() is None:
        try:
            ssh_process.terminate()
            ssh_process.wait(timeout=2)
        except:
            ssh_process.kill()


def signal_handler(signum, frame):
    """Ctrl+C handler"""
    print("\n⚠️  Interrupted (Ctrl+C)", flush=True)
    cleanup_remote_odoo()
    sys.exit(130)


def main():
    global ssh_process
    
    # Get arguments from PyCharm run configuration
    args = sys.argv[1:]
    
    print(f"🚀 Starting Odoo on VM: {HOST}")
    print(f"📋 Arguments: {' '.join(args) if args else '(none)'}")
    print()
    
    # Build SSH command (no sshpass, uses SSH key)
    ssh_cmd = [
        "ssh",
        "-t",  # Force TTY allocation for proper Ctrl+C handling
        f"{USER}@{HOST}",
        f"bash {REMOTE_SCRIPT} {' '.join(args)}"
    ]
    
    # Set Ctrl+C handler
    signal.signal(signal.SIGINT, signal_handler)
    
    try:
        # Run SSH with real-time output streaming
        ssh_process = subprocess.Popen(
            ssh_cmd,
            stdout=sys.stdout,
            stderr=sys.stderr,
            stdin=sys.stdin,
            bufsize=0  # Unbuffered for real-time logs
        )
        
        # Wait for completion
        returncode = ssh_process.wait()
        
        print(f"\n{'✅' if returncode == 0 else '❌'} Odoo exited with code: {returncode}")
        sys.exit(returncode)
        
    except KeyboardInterrupt:
        cleanup_remote_odoo()
        sys.exit(130)
    except Exception as e:
        print(f"❌ Error: {e}", flush=True)
        cleanup_remote_odoo()
        sys.exit(1)


if __name__ == "__main__":
    # Check SSH connectivity
    test_cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", 
                f"{USER}@{HOST}", "echo 'SSH OK'"]
    
    result = subprocess.run(test_cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("❌ SSH connection failed!")
        print("Please set up SSH key authentication:")
        print()
        print("1. Generate key: ssh-keygen -t ed25519")
        print(f"2. Copy to VM: ssh-copy-id {USER}@{HOST}")
        print("3. Test: ssh odoo@odoo-vm 'echo OK'")
        sys.exit(1)
    
    main()
