#!/usr/bin/env python3
import subprocess
import sys

# SSH კონფიგურაცია
HOST = "odoo-vm"  # VirtualBox-ის hostname (ან 192.168.1.50)
USER = "odoo"
PASSWORD = "1234"  # 🔑 აქ ჩაწერე შენი პაროლი
REMOTE_SCRIPT = "/home/odoo/run.sh"  # VirtualBox-ში run.sh-ის ადგილმდებარეობა

def main():
    print("📋 Arguments received:", sys.argv)
    
    # sys.argv[0] არის თავად სკრიპტის სახელი, დანარჩენი არის არგუმენტები
    args = sys.argv[1:]  # ['-d', 'swisscapital', '--dev', 'xml', '-u', 'sale']
    
    # SSH ბრძანება sshpass-ით
    cmd = [
        "sshpass", "-p", PASSWORD,
        "ssh", "-o", "StrictHostKeyChecking=no", f"{USER}@{HOST}",
        "bash", REMOTE_SCRIPT
    ]
    
    # ყველა არგუმენტის გადაცემა run.sh-ს
    # Python-დან: -d swisscapital --dev xml -u sale
    # run.sh მიიღებს: -d swisscapital --dev xml -u sale
    cmd.extend(args)
    
    print("🚀 Executing command:")
    # პაროლს არ ვაჩვენებთ
    safe_cmd = ["sshpass", "-p", "***", "ssh", "-o", "StrictHostKeyChecking=no",
                f"{USER}@{HOST}", "bash", REMOTE_SCRIPT] + args
    print(" ".join(safe_cmd))
    print()
    
    # SSH-ით გაშვება და რეალურ დროში შედეგის ჩვენება
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    
    try:
        for line in proc.stdout:
            print(line, end="")
            sys.stdout.flush()
    except KeyboardInterrupt:
        print("\n⚠️  Interrupted by user (Ctrl+C)")
        print("🛑 Stopping Odoo on VirtualBox...")
        
        # VirtualBox-ზე Odoo-ს გაჩერება (Python პროცესი)
        stop_cmd = [
            "sshpass", "-p", PASSWORD,
            "ssh", "-o", "StrictHostKeyChecking=no", f"{USER}@{HOST}",
            "bash", "-c", 
            "pkill -f 'python.*odoo-bin'; pkill -f 'bash.*run.sh'"
        ]
        
        result = subprocess.run(stop_cmd, capture_output=True, text=True)
        
        if result.returncode == 0 or result.returncode == 1:  # 1 = no process found (ეს ნორმალურია)
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
    sys.exit(main())
