#!/usr/bin/env pwsh
# ===============================================================
# SSH Key Setup for Odoo VM - Windows
# ===============================================================

$ErrorActionPreference = "Stop"

# ==================== კონფიგურაცია ====================
$VM_HOST = "odoo-vm"
$VM_USER = "odoo"
$VM_PASS = "1234"  # 🔑 შეიცვალე თუ სხვა პაროლი გაქვს

Write-Host "🔐 SSH Key Setup for Odoo VM (Windows)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. შემოწმება: SSH client დაინსტალირებული?
Write-Host "🔍 Checking SSH client..." -ForegroundColor Yellow
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ SSH client not found!" -ForegroundColor Red
    Write-Host "Install with: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ SSH client found" -ForegroundColor Green

# 2. .ssh directory
$SSH_DIR = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $SSH_DIR)) {
    Write-Host "📁 Creating .ssh directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $SSH_DIR -Force | Out-Null
}

# 3. SSH key generation
$KEY_FILE = "$SSH_DIR\id_ed25519"
if (Test-Path $KEY_FILE) {
    Write-Host "✅ SSH key already exists: $KEY_FILE" -ForegroundColor Green
} else {
    Write-Host "🔑 Generating SSH key..." -ForegroundColor Yellow
    ssh-keygen -t ed25519 -f $KEY_FILE -N '""' -C "odoo-vm-key"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to generate SSH key!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ SSH key generated" -ForegroundColor Green
}

# 4. Public key-ის წაკითხვა
$PUB_KEY = Get-Content "$KEY_FILE.pub" -Raw

# 5. VM connection test
Write-Host ""
Write-Host "🌐 Testing VM connection..." -ForegroundColor Yellow
$testConnection = Test-Connection -ComputerName $VM_HOST -Count 1 -Quiet
if (-not $testConnection) {
    Write-Host "❌ Cannot reach VM: $VM_HOST" -ForegroundColor Red
    Write-Host "Make sure VM is running and network is configured" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ VM is reachable" -ForegroundColor Green

# 6. sshpass installed?
$SSHPASS_AVAILABLE = Get-Command sshpass -ErrorAction SilentlyContinue
if (-not $SSHPASS_AVAILABLE) {
    Write-Host ""
    Write-Host "⚠️  sshpass not found - manual password entry required" -ForegroundColor Yellow
    Write-Host "   Install with: choco install sshpass (optional)" -ForegroundColor Gray
    Write-Host ""
    
    # Manual method
    Write-Host "📤 Copying public key to VM..." -ForegroundColor Yellow
    Write-Host "   You will be prompted for password: $VM_PASS" -ForegroundColor Gray
    Write-Host ""
    
    $setupScript = @"
mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUB_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo 'SSH_KEY_INSTALLED'
"@
    
    $result = ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" $setupScript
    
    if ($result -match "SSH_KEY_INSTALLED") {
        Write-Host "✅ Public key copied to VM" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to copy public key" -ForegroundColor Red
        exit 1
    }
} else {
    # Automatic with sshpass
    Write-Host "📤 Copying public key to VM (automatic)..." -ForegroundColor Yellow
    
    $setupScript = @"
mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUB_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo 'SSH_KEY_INSTALLED'
"@
    
    $result = sshpass -p $VM_PASS ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" $setupScript
    
    if ($result -match "SSH_KEY_INSTALLED") {
        Write-Host "✅ Public key copied to VM" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to copy public key" -ForegroundColor Red
        exit 1
    }
}

# 7. SSH Config ფაილის შექმნა
$SSH_CONFIG = "$SSH_DIR\config"
Write-Host ""
Write-Host "📝 Creating SSH config..." -ForegroundColor Yellow

# წაშალე ძველი odoo-vm entry თუ არსებობს
if (Test-Path $SSH_CONFIG) {
    $configContent = Get-Content $SSH_CONFIG -Raw
    $configContent = $configContent -replace "(?ms)Host odoo-vm.*?(?=Host |\z)", ""
    Set-Content -Path $SSH_CONFIG -Value $configContent.Trim()
}

# დაამატე ახალი entry
$newConfig = @"

Host odoo-vm
    HostName $VM_HOST
    User $VM_USER
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@

Add-Content -Path $SSH_CONFIG -Value $newConfig
Write-Host "✅ SSH config created: $SSH_CONFIG" -ForegroundColor Green

# 8. ტესტი
Write-Host ""
Write-Host "🧪 Testing SSH connection (without password)..." -ForegroundColor Yellow
$testResult = ssh $VM_USER@$VM_HOST "echo '✅ SSH key authentication works!'"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "✅ SSH key setup completed successfully!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 You can now SSH without password:" -ForegroundColor Cyan
    Write-Host "   ssh $VM_USER@$VM_HOST" -ForegroundColor White
    Write-Host ""
    Write-Host "🚀 Ready to use odoo_runner.py with PyCharm!" -ForegroundColor Cyan
} else {
    Write-Host "❌ SSH test failed!" -ForegroundColor Red
    Write-Host "Please check the setup manually" -ForegroundColor Yellow
    exit 1
}