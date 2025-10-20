@echo off
REM ===============================================================
REM SSH Key Setup for Odoo VirtualBox Manager (Windows)
REM ===============================================================

setlocal enabledelayedexpansion

echo.
echo ================================================
echo SSH Key Setup for Odoo VirtualBox Manager
echo ================================================
echo.

REM Check if ssh is available
where ssh >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] SSH client not found!
    echo.
    echo Please install OpenSSH Client:
    echo   1. Open Settings
    echo   2. Go to Apps ^> Optional Features
    echo   3. Click "Add a feature"
    echo   4. Search for "OpenSSH Client"
    echo   5. Install it
    echo.
    pause
    exit /b 1
)

echo [OK] SSH client found
echo.

REM Get VM IP address from user
set /p VM_IP="Enter your VirtualBox VM IP (e.g., 192.168.1.101): "
if "%VM_IP%"=="" (
    echo [ERROR] IP address cannot be empty
    pause
    exit /b 1
)

echo.
echo VM IP: %VM_IP%
echo.

REM Check if SSH key already exists
set SSH_KEY=%USERPROFILE%\.ssh\id_rsa
if exist "%SSH_KEY%" (
    echo [WARNING] SSH key already exists: %SSH_KEY%
    set /p OVERWRITE="Overwrite existing key? (y/n): "
    if /i not "!OVERWRITE!"=="y" (
        echo Keeping existing key...
        goto :COPY_KEY
    )
)

REM Generate SSH key
echo.
echo [1/3] Generating SSH key...
echo.

ssh-keygen -t rsa -b 4096 -f "%SSH_KEY%" -N "" -C "odoo-vm-key"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to generate SSH key
    pause
    exit /b 1
)

echo.
echo [OK] SSH key generated: %SSH_KEY%
echo.

:COPY_KEY

REM Copy key to VM
echo [2/3] Copying SSH key to VM...
echo.
echo You will be prompted for the VM password (default: 1234)
echo.

type "%SSH_KEY%.pub" | ssh odoo@%VM_IP% "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to copy SSH key to VM
    echo.
    echo Troubleshooting:
    echo   1. Check if VM is running
    echo   2. Verify IP address is correct
    echo   3. Make sure you can ping the VM: ping %VM_IP%
    echo   4. Try manual SSH: ssh odoo@%VM_IP%
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] SSH key copied to VM
echo.

REM Test connection
echo [3/3] Testing SSH connection...
echo.

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL odoo@%VM_IP% "echo 'Connection successful!'"

if %errorlevel% neq 0 (
    echo.
    echo [WARNING] SSH test failed, but key was copied
    echo Try running: ssh odoo@%VM_IP%
    echo.
) else (
    echo.
    echo [OK] SSH connection successful!
    echo.
)

REM Add to hosts file
echo.
echo ================================================
echo Setup Complete!
echo ================================================
echo.
echo Next steps:
echo.
echo 1. Add VM to hosts file (requires Administrator):
echo    - Open Notepad as Administrator
echo    - Open: C:\Windows\System32\drivers\etc\hosts
echo    - Add line: %VM_IP%    odoo-vm
echo    - Save file
echo.
echo 2. Update odoo-restart-windows.py:
echo    - Open: scripts\odoo-restart-windows.py
echo    - Verify HOST = "odoo-vm" (or "%VM_IP%")
echo.
echo 3. Test connection:
echo    - Run: python scripts\odoo-restart-windows.py -d swisscapital --dev xml
echo.
echo.

REM Offer to add to hosts file
set /p ADD_HOSTS="Do you want to add VM to hosts file now? (requires Admin) (y/n): "
if /i "!ADD_HOSTS!"=="y" (
    echo.
    echo Adding to hosts file...
    echo %VM_IP%    odoo-vm >> C:\Windows\System32\drivers\etc\hosts 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Added to hosts file
    ) else (
        echo [WARNING] Failed - please add manually (run as Administrator^)
    )
)

echo.
pause