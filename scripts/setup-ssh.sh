#!/usr/bin/env bash
# ===============================================================
# SSH Key Setup for Odoo VM - Linux/macOS
# ===============================================================

set -euo pipefail

# ==================== კონფიგურაცია ====================
VM_HOST="odoo-vm"
VM_USER="odoo"
VM_PASS="1234"  # 🔑 შეიცვალე თუ სხვა პაროლი გაქვს

echo "🔐 SSH Key Setup for Odoo VM (Linux/macOS)"
echo "=========================================="
echo ""

# 1. SSH client check
echo "🔍 Checking SSH client..."
if ! command -v ssh &>/dev/null; then
    echo "❌ SSH client not found!"
    echo "Install with: sudo apt install openssh-client"
    exit 1
fi
echo "✅ SSH client found"

# 2. .ssh directory
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# 3. SSH key generation
KEY_FILE="$SSH_DIR/id_ed25519"
if [[ -f "$KEY_FILE" ]]; then
    echo "✅ SSH key already exists: $KEY_FILE"
else
    echo "🔑 Generating SSH key..."
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "odoo-vm-key"
    echo "✅ SSH key generated"
fi

# 4. Public key წაკითხვა
PUB_KEY=$(cat "$KEY_FILE.pub")

# 5. VM connection test
echo ""
echo "🌐 Testing VM connection..."
if ! ping -c 1 -W 2 "$VM_HOST" &>/dev/null; then
    echo "❌ Cannot reach VM: $VM_HOST"
    echo "Make sure VM is running and network is configured"
    exit 1
fi
echo "✅ VM is reachable"

# 6. sshpass check
SSHPASS_AVAILABLE=false
if command -v sshpass &>/dev/null; then
    SSHPASS_AVAILABLE=true
fi

echo ""
if [[ "$SSHPASS_AVAILABLE" == true ]]; then
    echo "📤 Copying public key to VM (automatic)..."
    
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" \
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUB_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    
    echo "✅ Public key copied to VM"
else
    echo "⚠️  sshpass not found - manual password entry required"
    echo "   Install with: sudo apt install sshpass (optional)"
    echo ""
    echo "📤 Copying public key to VM..."
    echo "   You will be prompted for password: $VM_PASS"
    echo ""
    
    ssh-copy-id -o StrictHostKeyChecking=no -i "$KEY_FILE" "$VM_USER@$VM_HOST"
    
    echo "✅ Public key copied to VM"
fi

# 7. SSH Config file
SSH_CONFIG="$SSH_DIR/config"
echo ""
echo "📝 Creating SSH config..."

# Remove old odoo-vm entry if exists
if [[ -f "$SSH_CONFIG" ]]; then
    sed -i.bak '/^Host odoo-vm$/,/^$/d' "$SSH_CONFIG" 2>/dev/null || true
fi

# Add new entry
cat >> "$SSH_CONFIG" << EOF

Host odoo-vm
    HostName $VM_HOST
    User $VM_USER
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chmod 600 "$SSH_CONFIG"
echo "✅ SSH config created: $SSH_CONFIG"

# 8. Test
echo ""
echo "🧪 Testing SSH connection (without password)..."
if ssh "$VM_USER@$VM_HOST" "echo '✅ SSH key authentication works!'" 2>/dev/null; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ SSH key setup completed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🎉 You can now SSH without password:"
    echo "   ssh $VM_USER@$VM_HOST"
    echo ""
    echo "🚀 Ready to use odoo_runner.py with PyCharm!"
else
    echo "❌ SSH test failed!"
    echo "Please check the setup manually"
    exit 1
fi