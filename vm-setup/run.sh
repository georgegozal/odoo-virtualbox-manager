#!/bin/bash
# ------------------------------------------------------
# Odoo Run Script (George@development) - Debug Version
# ------------------------------------------------------

# Odoo და კონფიგურაციის ფაილის ადგილები
ODOO_DIR="/mnt/odoo11/odoo"
CONF_DIR="/mnt/odoo11/conf"
DEFAULT_CONF="odoo_vb.conf"
PYTHON="/home/odoo/.venv/bin/python3.7"

# დეფოლტური მნიშვნელობები
DEFAULT_DB="swisscapital"
DB_NAME=""
MODULES=""
DEV_MODE=""
DEBUG_MODE=false
CONF_FILE=""

# ფუნქცია Odoo პროცესის გასაჩერებლად
stop_odoo() {
    echo "🛑 Stopping existing Odoo processes..."
    
    # ყველა odoo-bin პროცესის გაჩერება
    PIDS=$(pgrep -f "python.*odoo-bin")
    if [ -n "$PIDS" ]; then
        echo "   Found PIDs: $PIDS"
        for PID in $PIDS; do
            echo "   Killing PID: $PID"
            kill -15 $PID 2>/dev/null
        done
        sleep 2
        
        # Force kill თუ საჭიროა
        PIDS=$(pgrep -f "python.*odoo-bin")
        if [ -n "$PIDS" ]; then
            for PID in $PIDS; do
                kill -9 $PID 2>/dev/null
            done
        fi
        echo "✅ All Odoo processes stopped"
    else
        echo "ℹ️  No running Odoo processes found"
    fi
}

# პარამეტრების დამუშავება
while [[ $# -gt 0 ]]; do
  case $1 in
    -u)
      MODULES="$2"
      shift 2
      ;;
    -d)
      DB_NAME="$2"
      shift 2
      ;;
    --dev)
      DEV_MODE="$2"
      shift 2
      ;;
    --debug)
      DEBUG_MODE=true
      shift
      ;;
    -c|--config)
      CONF_FILE="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: $0 [-d dbname] [-u modules] [--dev mode] [--debug] [-c config_file]"
      exit 1
      ;;
  esac
done

# შეცვალეთ სამუშაო კატალოგი Odoo დირექტორიად
cd "$ODOO_DIR" || exit 1

# 🛑 ჯერ გავაჩეროთ Odoo
stop_odoo

# კონფიგურაციის ფაილის დადგენა
if [ -z "$CONF_FILE" ]; then
    CONF_FILE="$DEFAULT_CONF"
    echo "⚠️  Config file not specified, using default: $CONF_FILE"
fi

# თუ მხოლოდ სახელია (არა სრული გზა), დავამატოთ CONF_DIR
if [[ ! "$CONF_FILE" = /* ]]; then
    CONF_FILE="$CONF_DIR/$CONF_FILE"
fi

# კონფიგურაციის ფაილის არსებობის შემოწმება
if [ ! -f "$CONF_FILE" ]; then
    echo "❌ Config file not found: $CONF_FILE"
    echo ""
    echo "Available config files in $CONF_DIR:"
    ls -1 "$CONF_DIR"/*.conf "$CONF_DIR"/*.cfg 2>/dev/null || echo "  (none found)"
    exit 1
fi

echo "✅ Using config file: $CONF_FILE"

# თუ მონაცემთა ბაზა არ არის მითითებული, გამოიყენეთ დეფოლტური
if [ -z "$DB_NAME" ]; then
    DB_NAME="$DEFAULT_DB"
    echo "⚠️  Database not provided, using default: $DB_NAME"
fi

# Odoo-ს გაშვების ბრძანება
ODOO_CMD="$PYTHON odoo-bin -c $CONF_FILE -d $DB_NAME"

# თუ მოდულები მითითებულია, განახლდება
if [ -n "$MODULES" ]; then
    echo "🔄 Updating modules: $MODULES on database: $DB_NAME"
    ODOO_CMD="$ODOO_CMD -u $MODULES"
fi

# თუ dev რეჟიმი მითითებულია
if [ -n "$DEV_MODE" ]; then
    echo "🚀 Starting Odoo in developer mode (--dev=$DEV_MODE)"
    ODOO_CMD="$ODOO_CMD --dev=$DEV_MODE"
else
    # თუ მოდულები არ განახლდება და dev რეჟიმი არ არის მითითებული
    if [ -z "$MODULES" ]; then
        echo "🚀 Starting Odoo in developer mode (--dev=xml) [default]"
        ODOO_CMD="$ODOO_CMD --dev=xml"
    fi
fi

# Debug რეჟიმი
if [ "$DEBUG_MODE" = true ]; then
    echo "🐛 Debug mode enabled - debugpy on port 5678"
    # debugpy დაყენება (თუ არ არის)
    $PYTHON -m pip install debugpy --quiet 2>/dev/null || true
    
    # Odoo-ს გაშვება debugpy-ით
    ODOO_CMD="$PYTHON -m debugpy --listen 0.0.0.0:5678 --wait-for-client odoo-bin -c $CONF_FILE -d $DB_NAME"
    
    if [ -n "$MODULES" ]; then
        ODOO_CMD="$ODOO_CMD -u $MODULES"
    fi
    
    if [ -n "$DEV_MODE" ]; then
        ODOO_CMD="$ODOO_CMD --dev=$DEV_MODE"
    elif [ -z "$MODULES" ]; then
        ODOO_CMD="$ODOO_CMD --dev=xml"
    fi
fi

# Odoo-ს გაშვება
echo "📝 Executing: $ODOO_CMD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
eval $ODOO_CMD