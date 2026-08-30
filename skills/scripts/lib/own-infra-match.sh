#!/usr/bin/env bash
# own-infra allowlist matcher (sourced by case-init.sh and case-guard.sh).
# PowerShell parity: skills/scripts/lib/OwnInfra.ps1
#
# Functions (all return 0 = allowed / 1 = not allowed):
#   own_infra_host_allowed <allowlist_file> <asset>
# Helpers:
#   own_infra_normalize_asset <asset>   -> prints bare host (or empty)
#   own_infra_ip_in_cidr <ipv4> <cidr>
#
# Allowlist format: one entry per line, '#' starts a comment.
#   example.com          exact host or any subdomain (case-insensitive)
#   cidr:10.0.0.0/8      IPv4 CIDR range

own_infra_normalize_asset() {
  local a="$1"
  a="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  a="${a#*://}"          # strip scheme
  a="${a##*@}"           # strip userinfo
  a="${a%%/*}"           # strip path
  a="${a%%\?*}"         # strip query
  a="${a%%:*}"           # strip port
  a="${a#.}"             # strip leading dot
  a="${a%.}"             # strip trailing dot
  printf '%s' "$a"
}

own_infra_ip_in_cidr() {
  local ip="$1" cidr="$2" base bits
  [[ "$cidr" == */* ]] || return 1
  base="${cidr%%/*}"; bits="${cidr##*/}"
  [[ "$bits" =~ ^[0-9]+$ ]] || return 1
  (( bits >= 0 && bits <= 32 )) || return 1
  local a b c d e f g h
  IFS=. read -r a b c d <<< "$ip"
  IFS=. read -r e f g h <<< "$base"
  local v
  for v in "$a" "$b" "$c" "$d" "$e" "$f" "$g" "$h"; do
    [[ "$v" =~ ^[0-9]+$ ]] || return 1
    (( v <= 255 )) || return 1
  done
  local ipint=$(( (a << 24) | (b << 16) | (c << 8) | d ))
  local baseint=$(( (e << 24) | (f << 16) | (g << 8) | h ))
  local mask
  if (( bits == 0 )); then mask=0; else mask=$(( (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF )); fi
  (( (ipint & mask) == (baseint & mask) ))
}

own_infra_host_allowed() {
  local allowlist="$1" asset="$2" host raw entry
  host="$(own_infra_normalize_asset "$asset")"
  [[ -n "$host" ]] || return 1
  [[ -f "$allowlist" ]] || return 1
  while IFS= read -r raw || [[ -n "$raw" ]]; do
    entry="${raw%%#*}"
    entry="$(printf '%s' "$entry" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -n "$entry" ]] || continue
    entry="$(printf '%s' "$entry" | tr '[:upper:]' '[:lower:]')"
    if [[ "$entry" == cidr:* ]]; then
      if own_infra_ip_in_cidr "$host" "${entry#cidr:}"; then return 0; fi
    else
      if [[ "$host" == "$entry" || "$host" == *."$entry" ]]; then return 0; fi
    fi
  done < "$allowlist"
  return 1
}
