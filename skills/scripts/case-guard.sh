#!/usr/bin/env bash
# Lightweight scope gate before ACT. Exit 0=ok, 2=not ready, 1=usage/error.
# Usage:
#   bash skills/scripts/case-guard.sh --case-root work/my-case
#   bash skills/scripts/case-guard.sh --case-root work/my-case --force  # compatibility flag; never bypasses scope hard gates
set -euo pipefail

CASE_ROOT=""
FORCE=0
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -CaseRoot|--case-root) CASE_ROOT="${2:-}"; shift 2 ;;
    -Force|--force) FORCE=1; shift ;;
    -Quiet|--quiet) QUIET=1; shift ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "Unknown arg: \"$1\"" >&2; exit 1 ;;
  esac
done

info() { [[ $QUIET -eq 1 ]] || echo "$*"; }

if [[ -z "$CASE_ROOT" ]]; then
  echo "ERROR: --case-root required" >&2
  exit 1
fi
if [[ ! -d "$CASE_ROOT" ]]; then
  echo "ERROR: CaseRoot missing: $CASE_ROOT" >&2
  exit 1
fi

SCOPE_PATH="$CASE_ROOT/scope.md"
if [[ ! -f "$SCOPE_PATH" ]]; then
  echo "ERROR: scope.md missing under $CASE_ROOT" >&2
  exit 1
fi

SCOPE="$(cat "$SCOPE_PATH")"
ISSUES=()

# Read fields only from their contract sections. A status-like line in notes,
# evidence, or ops_refs must never satisfy the authorization gate.
section_field() {
  local section="$1"
  local field="$2"
  awk -v wanted_section="$section" -v wanted_field="$field" '
    /^##[[:space:]]+/ {
      heading=$0
      sub(/^##[[:space:]]+/, "", heading)
      active=(tolower(heading)==tolower(wanted_section))
      next
    }
    active {
      line=$0
      pattern="^[[:space:]]*-[[:space:]]*" wanted_field ":[[:space:]]*"
      if (line ~ pattern) {
        sub(pattern, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        print line
        exit
      }
    }
  ' "$SCOPE_PATH"
}

auth_granted=0
if [[ "$(section_field auth status | tr '[:upper:]' '[:lower:]')" == "granted" ]]; then
  auth_granted=1
fi
[[ $auth_granted -eq 1 ]] || ISSUES+=("auth.status is not granted")

net_mode="$(section_field network_profile mode | tr -d '\r' | awk '{print $1}')"
if [[ -z "$net_mode" ]]; then
  ISSUES+=("network_profile.mode missing")
else
  case "$net_mode" in
    offline)
      if ! printf '%s' "$SCOPE" | grep -Eiq 'sample|offline.?path|local.?sample|\.apk\b|\.bin\b|\.exe\b'; then
        ISSUES+=("network_profile.mode is offline without offline sample cue")
      fi
      ;;
    lab_only|authorized_target_only|unrestricted_lab) ;;
    *) ISSUES+=("network_profile.mode is unsupported: $net_mode") ;;
  esac
fi

has_asset=0
# crude: look for indented list items after assets: that are not []
if printf '%s\n' "$SCOPE" | awk '
  BEGIN{inscope=0; inassets=0}
  /^##[[:space:]]*in_scope/ {inscope=1; inassets=0; next}
  /^##[[:space:]]/ {if(inscope){inscope=0; inassets=0}}
  inscope && /-[[:space:]]*assets:/ {inassets=1; next}
  inscope && inassets && /^[[:space:]]+-[[:space:]]+/ {
    line=$0
    sub(/^[[:space:]]+-[[:space:]]+/,"",line)
    if (line !~ /^\[/ && length(line)>0) { found=1 }
  }
  END{ exit(found?0:1) }
'; then
  has_asset=1
fi
if [[ $has_asset -eq 0 && "$net_mode" != "offline" ]]; then
  ISSUES+=("in_scope.assets appears empty")
fi

# own-infra defense-in-depth: a scope claiming the own-infra preset (or the
# own_infra auth basis) must list ONLY assets covered by the ownership
# allowlist. Hand-edited scopes are re-verified here.
oi_preset="$(section_field meta preset | tr '[:upper:]' '[:lower:]')"
oi_basis="$(section_field auth basis | tr '[:upper:]' '[:lower:]')"
own_infra_scope=0
case "$oi_preset" in own-infra|chef-infra) own_infra_scope=1 ;; esac
case "$oi_basis" in own_infra) own_infra_scope=1 ;; esac
if [[ $own_infra_scope -eq 1 ]]; then
  SCRIPT_DIR_GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ALLOWLIST="$SCRIPT_DIR_GUARD/../config/own-infra.allowlist"
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR_GUARD/lib/own-infra-match.sh"
  if [[ ! -f "$ALLOWLIST" ]]; then
    ISSUES+=("own-infra scope: allowlist missing: $ALLOWLIST")
  else
    while IFS= read -r oi_asset; do
      if [[ -z "$oi_asset" ]]; then continue; fi
      if ! own_infra_host_allowed "$ALLOWLIST" "$oi_asset"; then
        ISSUES+=("own-infra scope: asset not in own-infra.allowlist: $oi_asset")
      fi
    done < <(printf '%s\n' "$SCOPE" | awk '
      BEGIN{inscope=0; inassets=0}
      /^##[[:space:]]*in_scope/ {inscope=1; inassets=0; next}
      /^##[[:space:]]/ {if(inscope){inscope=0; inassets=0}}
      inscope && /-[[:space:]]*assets:/ {inassets=1; next}
      inscope && inassets && /^[[:space:]]+-[[:space:]]+/ {
        line=$0
        sub(/^[[:space:]]+-[[:space:]]+/, "", line)
        if (line !~ /^\[\]/ && length(line)>0) print line
      }')
  fi
fi

ready=0
if [[ "$(section_field signoff ready_for_act | tr '[:upper:]' '[:lower:]')" == "true" ]]; then
  ready=1
fi
[[ $ready -eq 1 ]] || ISSUES+=("ready_for_act is not true")

if [[ ${#ISSUES[@]} -eq 0 ]]; then
  info "CASE-GUARD OK: $CASE_ROOT"
  exit 0
fi

echo "CASE-GUARD NOT READY: $CASE_ROOT"
for i in "${ISSUES[@]}"; do echo " - $i"; done

if [[ $FORCE -eq 1 ]]; then
  echo "CASE-GUARD: --force does not bypass scope hard gates."
fi

echo "Fix scope (or re-run case-init with --auth-granted --target-url ...)."
exit 2
