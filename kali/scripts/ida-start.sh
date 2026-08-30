#!/usr/bin/env bash
# ida-start.sh — Kali Linux edition: start the IDA MCP service
# Equivalent to the Windows edition's ida-start.ps1
#
# Usage:
#   bash ida-start.sh [options]
#
# Options:
#   --help              Show help
#   --check             Check the current state only
#   --stop              Stop the service

set -euo pipefail

# ─── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KALI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$KALI_DIR/.." && pwd)"

# ─── Helpers ───────────────────────────────────────────────────────────────────

log_info() { echo -e "\033[36m[INFO]\033[0m $*"; }
log_ok() { echo -e "\033[32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[33m[WARN]\033[0m $*"; }
log_err() { echo -e "\033[31m[ERR]\033[0m $*"; }

# ─── Service startup ───────────────────────────────────────────────────────────

start_service() {
    # Check whether the service is already running
    if nc -z 127.0.0.1 13337 2>/dev/null; then
        log_ok "IDA MCP already running (port 13337)"
        return 0
    fi

    log_info "Starting IDA MCP ..."

    # Start the service
    if ! bash ida-daemon.sh start; then
        log_err "Failed to start the IDA daemon"
        return 1
    fi

    log_ok "IDA MCP started"
}

check_state() {
    log_info "Current IDA MCP state:"

    # Check whether the port is listening
    if nc -z 127.0.0.1 13337 2>/dev/null; then
        log_ok "Port 13337 is listening"
    else
        log_warn "Port 13337 is not listening"
    fi

    # Check whether the IDA Pro installation is present
    if [[ -d /opt/idapro ]]; then
        log_ok "IDA Pro installation present"
    else
        log_warn "IDA Pro installation missing"
    fi

    # Check MCP status
    if command -v ida-pro-mcp &>/dev/null; then
        log_ok "ida-pro-mcp available"
    else
        log_warn "ida-pro-mcp not installed"
    fi
}

# ─── Main entry ────────────────────────────────────────────────────────────────

case "${1:-}" in
    --help|-h)
        show_help
        ;;
    --check)
        check_state
        ;;
    *)
        start_service
        ;;
esac
