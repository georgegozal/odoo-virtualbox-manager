#!/usr/bin/env bash
# ------------------------------------------------------
# Odoo Run Script
# - resolve config as CONF_DIR + name (or absolute)
# - parse port from config and stop ONLY that instance
# - no default DB; -d optional
# - safe argv handling (no eval)
# - robust PID detection (lsof → fuser → ss/netstat)
#
# NEW:
# - default runs detached in screen (so multiple instances can run)
# - use --logs to run in foreground (show logs in terminal)
# - detached mode logs to ~/.odoo/logs/<session>.log
# ------------------------------------------------------

set -Eeuo pipefail
IFS=$'\n\t'

# === Load .env file if present ===
ENV_FILE="$HOME/.env"
if [[ -f "$ENV_FILE" ]]; then
  echo "Loading environment variables from $ENV_FILE"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

# === Paths ===
ODOO_DIR="/home/odoo/.odoo"
CONF_DIR="/home/odoo/odoo"
DEFAULT_CONF="odoo_vb.conf"
PYTHON="/home/odoo/.venv/bin/python3.7"

# === Defaults ===
DB_NAME=""
MODULES=""
DEV_MODE=""
DEBUG_MODE=false
CONF_FILE=""

# Logging / detach defaults
LOGS_MODE=false                  # when true => foreground
LOG_DIR="$HOME/.odoo/logs"

usage() {
  echo "Usage: $0 [-d dbname] [-u modules] [--dev mode] [--debug] [-c config_name_or_path] [--logs]"
  echo "  --logs   Run in foreground (do not detach). Default is detached via screen."
}

# --- Helpers ---
normalize_conf_path() {
  local p="$1"
  if [[ "$p" != /* ]]; then p="$CONF_DIR/$p"; fi
  readlink -f "$p"
}

get_port_from_conf() {
  local conf="$1"
  awk -F= '
    BEGIN{port=""}
    /^\s*(xmlrpc_port|http_port)\s*=/ {
      v=$2; gsub(/[[:space:]]/,"",v);
      if (v ~ /^[0-9]+$/) { print v; exit }
    }' "$conf"
}

pids_listen_on_port() {
  # Try lsof (best), then fuser, then ss/netstat
  local port="$1" out=""
  if command -v lsof >/dev/null 2>&1; then
    out=$(lsof -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null || true)
    if [[ -n "$out" ]]; then printf '%s\n' "$out" | sort -u; return 0; fi
  fi
  if command -v fuser >/dev/null 2>&1; then
    out=$(fuser -n tcp "$port" 2>/dev/null || true)
    if [[ -n "$out" ]]; then printf '%s\n' $out | sort -u; return 0; fi
  fi
  if command -v ss >/dev/null 2>&1; then
    out=$(ss -lptnH "sport = :$port" 2>/dev/null | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | sort -u || true)
    if [[ -n "$out" ]]; then printf '%s\n' "$out"; return 0; fi
  fi
  if command -v netstat >/dev/null 2>&1; then
    out=$(netstat -lptn 2>/dev/null | awk -v p=":$port" '$4 ~ p {print $7}' \
      | sed -n 's/.*\/\([0-9]\+\).*/\1/p' | sort -u || true)
    if [[ -n "$out" ]]; then printf '%s\n' "$out"; return 0; fi
  fi
  return 0
}

pids_matching_conf() {
  # Fallback: processes that have exact -c <conf_full_path> or --config=<conf_full_path>
  local conf_real="$1"
  ps -eo pid=,args= | awk -v conf="$conf_real" '
    tolower($0) ~ /odoo-bin/ {
      for (i=1; i<=NF; i++) {
        if ($i == "-c" && (i+1)<=NF && $(i+1) == conf) { print $1; break }
        if (index($i, "--config=" conf)) { print $1; break }
      }
    }' | sort -u
}

stop_odoo_targeted() {
  local conf_real="$1"
  local port="${2:-}"

  local targets=""
  if [[ -n "$port" ]]; then
    echo "Stopping instance listening on port: $port"
    targets=$(pids_listen_on_port "$port" || true)
  fi
  if [[ -z "$targets" ]]; then
    echo "Port match not found (or no port). Falling back to config match."
    targets=$(pids_matching_conf "$conf_real" || true)
  fi
  if [[ -z "$targets" ]]; then
    echo "No running Odoo process matched this instance."
    return 0
  fi

  echo "Target PIDs: $targets"
  while read -r pid; do [[ -n "$pid" ]] && kill -15 "$pid" 2>/dev/null || true; done <<< "$targets"
  sleep 2
  local still=""
  still=$(printf "%s\n" "$targets" | xargs -r -n1 -I{} sh -c 'kill -0 {} 2>/dev/null && echo {}' | tr '\n' ' ')
  if [[ -n "$still" ]]; then
    echo "Force killing: $still"
    printf "%s\n" $still | xargs -r -n1 kill -9 2>/dev/null || true
  fi
  echo "Instance processes stopped"
}

# === Parse args ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u)       [[ $# -ge 2 ]] || { echo "❌ -u requires value"; usage; exit 1; }; MODULES="$2"; shift 2;;
    -d)       [[ $# -ge 2 ]] || { echo "❌ -d requires value"; usage; exit 1; }; DB_NAME="$2"; shift 2;;
    --dev)    [[ $# -ge 2 ]] || { echo "❌ --dev requires value"; usage; exit 1; }; DEV_MODE="$2"; shift 2;;
    --debug)  DEBUG_MODE=true; shift;;
    --logs)   LOGS_MODE=true; shift;;
    -c|--config)
              [[ $# -ge 2 ]] || { echo "❌ $1 requires value"; usage; exit 1; }
              CONF_FILE="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *)        echo "❌ Unknown option: $1"; usage; exit 1;;
  esac
done

# === Sanity ===
[[ -x "$PYTHON" ]] || { echo "❌ Python not executable: $PYTHON"; exit 1; }
[[ -d "$ODOO_DIR" ]] || { echo "❌ Odoo dir not found: $ODOO_DIR"; exit 1; }

cd "$ODOO_DIR"

# --- Resolve config (CONF_DIR + name, or absolute) ---
if [[ -z "$CONF_FILE" ]]; then
  CONF_FILE="$DEFAULT_CONF"
  echo "Config not provided, using default: $CONF_FILE"
fi
CONF_FILE=$(normalize_conf_path "$CONF_FILE")
[[ -f "$CONF_FILE" ]] || {
  echo "❌ Config not found: $CONF_FILE"
  echo "Available configs in $CONF_DIR:"
  ls -1 "$CONF_DIR"/*.conf "$CONF_DIR"/*.cfg 2>/dev/null || echo "  (none)"
  exit 1
}
echo "Using config: $CONF_FILE"

# --- Parse port & stop only this instance ---
PORT="$(get_port_from_conf "$CONF_FILE" || true)"
if [[ -n "$PORT" ]]; then
  echo "Parsed port from config: $PORT"
else
  echo "No port set in config; default 8069 may apply."
fi
stop_odoo_targeted "$CONF_FILE" "${PORT:-}"

# --- Guards ---
if [[ -n "$MODULES" && -z "$DB_NAME" ]]; then
  echo "❌ -u requires -d (database)."
  exit 1
fi

# --- Build command ---
CMD=( "$PYTHON" "odoo-bin" "-c" "$CONF_FILE" )
[[ -n "$DB_NAME" ]] && CMD+=( "-d" "$DB_NAME" )
[[ -n "$MODULES" ]] && { echo "Updating modules: $MODULES"; CMD+=( "-u" "$MODULES" ); }
if [[ -n "$DEV_MODE" ]]; then
  echo "Dev mode: --dev=$DEV_MODE"
  CMD+=( "--dev=$DEV_MODE" )
else
  [[ -z "$MODULES" ]] && { echo "Dev mode default: --dev=xml"; CMD+=( "--dev=xml" ); }
fi

# --- Debug wrapper ---
if [[ "$DEBUG_MODE" == true ]]; then
  echo "Debug mode enabled (debugpy :5678)"
  "$PYTHON" -m pip install debugpy --quiet >/dev/null 2>&1 || true
  CMD=( "$PYTHON" "-m" "debugpy" "--listen" "0.0.0.0:5678" "--wait-for-client" "odoo-bin" "-c" "$CONF_FILE" )
  [[ -n "$DB_NAME" ]] && CMD+=( "-d" "$DB_NAME" )
  [[ -n "$MODULES" ]] && CMD+=( "-u" "$MODULES" )
  if [[ -n "$DEV_MODE" ]]; then
    CMD+=( "--dev=$DEV_MODE" )
  else
    [[ -z "$MODULES" ]] && CMD+=( "--dev=xml" )
  fi
fi

# --- Session/log naming ---
mkdir -p "$LOG_DIR"

CONF_BASE="$(basename "$CONF_FILE")"
CONF_STEM="${CONF_BASE%.*}"
SESSION_NAME="${CONF_STEM}"

LOG_FILE="$LOG_DIR/${SESSION_NAME}.log"

# --- Run ---
printf 'Executing: '
for tok in "${CMD[@]}"; do printf '%q ' "$tok"; done
echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$LOGS_MODE" == true ]]; then
  # Foreground mode: show output in terminal
  exec "${CMD[@]}" >"${LOG_FILE}" 2>&1
else
  # Detached mode: run inside screen, log to file
  if ! command -v screen >/dev/null 2>&1; then
    echo "❌ screen is not installed. Install it: sudo apt-get install -y screen"
    exit 1
  fi

  # Build a safely-quoted command string
  printf -v CMD_STR '%q ' "${CMD[@]}"

  echo "Starting detached screen session: $SESSION_NAME"
  echo "Logging to: $LOG_FILE"
  echo "View logs:   tail -f '$LOG_FILE'"
  echo "Attach:      screen -r '$SESSION_NAME'"
  echo "Sessions:    screen -ls"

  # Start detached; also load ~/.env inside screen shell so variables exist there too
  screen -dmS "$SESSION_NAME" bash -lc "
    set -Eeuo pipefail
    ENV_FILE=\"\$HOME/.env\"
    if [[ -f \"\$ENV_FILE\" ]]; then
      set -a
      source \"\$ENV_FILE\"
      set +a
    fi
   
   exec $CMD_STR 2>&1 | tee "${LOG_FILE}"
  "

  exit 0
fi
