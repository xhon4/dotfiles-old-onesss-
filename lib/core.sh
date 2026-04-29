#!/usr/bin/env bash
# ================================================================
#  ricectl core library — logging, helpers, common functions
# ================================================================

set -euo pipefail

# Colors
readonly C_RESET='\e[0m'
readonly C_BLUE='\e[34m'
readonly C_GREEN='\e[32m'
readonly C_YELLOW='\e[33m'
readonly C_RED='\e[31m'
readonly C_CYAN='\e[36m'
readonly C_BOLD='\e[1m'

# Globals
RICECTL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
RICECTL_VERSION="$(cat "$RICECTL_ROOT/VERSION" 2>/dev/null || echo "unknown")"
RICECTL_LOG="$RICECTL_ROOT/ricectl.log"
DRY_RUN="${DRY_RUN:-false}"

# ---------------- LOGGING ----------------

info()    { echo -e "${C_BLUE}[>]${C_RESET} $1"; }
success() { echo -e "${C_GREEN}[✓]${C_RESET} $1"; }
warn()    { echo -e "${C_YELLOW}[!]${C_RESET} $1"; }
error()   { echo -e "${C_RED}[✗]${C_RESET} $1"; }
header()  { echo -e "\n${C_BOLD}${C_CYAN}═══ $1 ═══${C_RESET}\n"; }

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$RICECTL_LOG"
}

# ---------------- EXECUTION ----------------

# Idempotent run: logs and optionally dry-runs
run() {
    log "RUN: $*"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${C_YELLOW}[DRY]${C_RESET} $*"
    else
        # shellcheck disable=SC2294
        eval "$@"
    fi
}

# Run with sudo, idempotent
srun() {
    run "sudo $*"
}

# ---------------- CHECKS ----------------

require_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run as root. Use a normal user with sudo."
        exit 1
    fi
}

require_internet() {
    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        error "No internet connection"
        exit 1
    fi
}

require_command() {
    if ! command -v "$1" &>/dev/null; then
        error "Required command not found: $1"
        return 1
    fi
}

# Keep sudo alive in background; saves PID in SUDO_KEEPALIVE_PID for cleanup
sudo_keepalive() {
    sudo -v
    while true; do sudo -n true; sleep 30; kill -0 "$$" || exit; done 2>/dev/null &
    # shellcheck disable=SC2034  # consumed cross-file by ricectl
    SUDO_KEEPALIVE_PID=$!
}

# ---------------- YAML PARSER (minimal) ----------------
# Parses simple YAML into bash variables. Handles:
#   key: value  →  yaml_key="value"
#   list items under a key (- item) → yaml_key_0="item", yaml_key_1="item"...

parse_yaml() {
    local file="$1"
    local prefix="${2:-yaml}"
    local w='[a-zA-Z0-9_-]*'

    if [[ ! -f "$file" ]]; then
        error "YAML file not found: $file"
        return 1
    fi

    # Clear all previous variables with this prefix
    while IFS='=' read -r var _; do
        unset "$var"
    done < <(compgen -v "${prefix}_" 2>/dev/null || true)

    local current_key=""
    local list_index=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # key: value
        if [[ "$line" =~ ^($w):\ *(.*) ]]; then
            current_key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            list_index=0

            if [[ -n "$value" ]]; then
                # Remove surrounding quotes
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
                printf -v "${prefix}_${current_key//-/_}" '%s' "$value"
            fi

        # - list item
        elif [[ "$line" =~ ^[[:space:]]+-\ *(.*) ]]; then
            local value="${BASH_REMATCH[1]}"
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            printf -v "${prefix}_${current_key//-/_}_${list_index}" '%s' "$value"
            ((list_index++)) || true
            printf -v "${prefix}_${current_key//-/_}_count" '%s' "$list_index"
        fi
    done < "$file"
}

# Get all list items for a YAML key as array
yaml_list() {
    local prefix="$1"
    local key="${2//-/_}"
    local count_var="${prefix}_${key}_count"
    local count="${!count_var:-0}"
    local items=()

    for ((i=0; i<count; i++)); do
        local var="${prefix}_${key}_${i}"
        items+=("${!var}")
    done

    echo "${items[@]}"
}

# Count list items under a single top-level YAML section.
# Returns 0 when the section is absent or empty.
count_yaml_list() {
    local file="$1" section="$2"
    awk -v sec="^${section}:" '
        $0 ~ sec        { in_section = 1; next }
        /^[A-Za-z]/     { in_section = 0 }
        in_section && /^[[:space:]]+-[[:space:]]/ { n++ }
        END             { print n + 0 }
    ' "$file"
}

# ---------------- CONFIRM ----------------

confirm() {
    local msg="${1:-Continue?}"
    read -rp "$(echo -e "${C_YELLOW}[?]${C_RESET} $msg [y/N]: ")" answer
    [[ "$answer" =~ ^[Yy]$ ]]
}
