#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "=== Testing Bash Workflow ==="

# Test 1: case-init.sh creates proper structure
echo "[Test 1] case-init.sh basic execution"
bash "$SCRIPT_DIR/case-init.sh" \
  --hint "authorized web review" \
  --case-name "test-bash-01" \
  --package-root "$SCRATCH" \
  --auth-granted \
  --target-url "https://example.test/" \
  --network-profile "authorized_target_only" > /dev/null

if [ ! -f "$SCRATCH/work/test-bash-01/scope.md" ]; then
    echo "FAIL: scope.md not created"
    exit 1
fi

# Test 2: case-guard.sh validates valid scope
echo "[Test 2] case-guard.sh accepts valid scope"
if ! bash "$SCRIPT_DIR/case-guard.sh" --case-root "$SCRATCH/work/test-bash-01" > /dev/null; then
    echo "FAIL: case-guard rejected valid scope"
    exit 1
fi

# Test 3: case-guard.sh rejects invalid network mode
echo "[Test 3] case-guard.sh rejects invalid network mode"
sed -i 's/mode: authorized_target_only/mode: invalid_mode/g' "$SCRATCH/work/test-bash-01/scope.md"
if bash "$SCRIPT_DIR/case-guard.sh" --case-root "$SCRATCH/work/test-bash-01" > /dev/null 2>&1; then
    echo "FAIL: case-guard accepted invalid network mode"
    exit 1
fi

# Test 4: case-guard.sh rejects ungranted auth
echo "[Test 4] case-guard.sh rejects ungranted auth"
sed -i 's/mode: invalid_mode/mode: authorized_target_only/g' "$SCRATCH/work/test-bash-01/scope.md"
sed -i 's/status: granted/status: pending/g' "$SCRATCH/work/test-bash-01/scope.md"
if bash "$SCRIPT_DIR/case-guard.sh" --case-root "$SCRATCH/work/test-bash-01" > /dev/null 2>&1; then
    echo "FAIL: case-guard accepted pending auth"
    exit 1
fi

# Test 5: own-infra preset grants allowlisted hosts (domain + CIDR)
echo "[Test 5] case-init own-infra preset grants allowlisted host"
bash "$SCRIPT_DIR/case-init.sh" \
  --hint "own infra check" \
  --case-name "test-bash-05" \
  --package-root "$SCRATCH" \
  --preset own-infra \
  --targets "deepseek.chefgroep.online" > "$SCRATCH/own-infra-grant.log"
if ! grep -q "auth.status=granted" "$SCRATCH/own-infra-grant.log"; then
    echo "FAIL: own-infra preset did not grant allowlisted host"
    exit 1
fi
if ! bash "$SCRIPT_DIR/case-guard.sh" --case-root "$SCRATCH/work/test-bash-05" > /dev/null; then
    echo "FAIL: case-guard rejected own-infra granted scope"
    exit 1
fi

# Test 6: own-infra preset stays pending for a host outside the allowlist
echo "[Test 6] case-init own-infra preset stays pending for non-owned host"
bash "$SCRIPT_DIR/case-init.sh" \
  --hint "third party probe" \
  --case-name "test-bash-06" \
  --package-root "$SCRATCH" \
  --preset own-infra \
  --targets "example.com" > "$SCRATCH/own-infra-deny.log"
if ! grep -q "auth.status=pending" "$SCRATCH/own-infra-deny.log"; then
    echo "FAIL: own-infra preset granted a host outside own-infra.allowlist"
    exit 1
fi

# Test 7: case-guard re-verifies own-infra scope (hand-edited foreign asset)
echo "[Test 7] case-guard rejects foreign asset in own-infra scope"
sed -i 's|https://example.com|https://foreign.invalid|g' "$SCRATCH/work/test-bash-06/scope.md"
sed -i 's/status: pending/status: granted/' "$SCRATCH/work/test-bash-06/scope.md"
guard_output="$(bash "$SCRIPT_DIR/case-guard.sh" --case-root "$SCRATCH/work/test-bash-06" 2>&1)" && {
    echo "FAIL: case-guard accepted foreign asset under own-infra preset"
    exit 1
}
if ! grep -q "own-infra scope: asset not in own-infra.allowlist" <<< "$guard_output"; then
    echo "FAIL: case-guard rejected foreign asset for an unrelated reason"
    printf '%s\n' "$guard_output"
    exit 1
fi

# Test 8: generic private addressing is not ownership evidence
echo "[Test 8] own-infra preset keeps generic private IP pending"
bash "$SCRIPT_DIR/case-init.sh" \
  --hint "private range is not ownership" \
  --case-name "test-bash-08" \
  --package-root "$SCRATCH" \
  --preset own-infra \
  --targets "10.0.0.5" > "$SCRATCH/own-infra-private-deny.log"
if ! grep -q "auth.status=pending" "$SCRATCH/own-infra-private-deny.log"; then
    echo "FAIL: generic private IP was treated as operator-owned"
    exit 1
fi

echo "=== All Bash Workflow Tests Passed ==="
