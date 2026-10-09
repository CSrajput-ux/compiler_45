#!/usr/bin/env bash
set -euo pipefail

: "${COMPILER_API:?Set COMPILER_API, for example https://compiler.example.com}"
: "${COMPILER_TOKEN:?Set COMPILER_TOKEN to the private AUTHN_TOKEN from judge0.conf}"

api="${COMPILER_API%/}"
auth_header="X-Compiler-Token: ${COMPILER_TOKEN}"

echo "Checking language allowlist..."
languages="$(curl --fail --silent --show-error "$api/languages" -H "$auth_header")"
python3 - "$languages" <<'PY'
import json
import sys

rows = json.loads(sys.argv[1])
actual = {int(row["id"]) for row in rows}
expected = {50, 54, 60, 62, 63, 71, 82}
if actual != expected:
    print(f"Unexpected language IDs. Expected {sorted(expected)}, got {sorted(actual)}")
    raise SystemExit(1)
print("PASS: exactly the seven requested language IDs are visible.")
PY

echo "Checking Python code execution..."
result="$(curl --fail --silent --show-error \
  -X POST "$api/submissions?base64_encoded=false&wait=true" \
  -H "Content-Type: application/json" \
  -H "$auth_header" \
  -d '{"language_id":71,"source_code":"print(\"compiler45-ok\")","stdin":""}')"

python3 - "$result" <<'PY'
import json
import sys

result = json.loads(sys.argv[1])
status = result.get("status", {}).get("description", "unknown")
stdout = result.get("stdout") or ""
if status != "Accepted" or "compiler45-ok" not in stdout:
    print("Submission failed.")
    print("Status:", status)
    print("Compile output:", result.get("compile_output"))
    print("Stderr:", result.get("stderr"))
    print("Stdout:", stdout)
    raise SystemExit(1)
print("PASS: Python submission executed successfully.")
PY

echo "Smoke test passed."
