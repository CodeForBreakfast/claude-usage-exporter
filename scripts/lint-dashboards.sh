#!/usr/bin/env bash
# Lint Grafana dashboard JSON files for compatibility issues.
#
# Checks:
#   1. Query-type template variables must use object query format (Grafana 10+).
#      Plain-string queries silently fail in newer Grafana.
#   2. Repeat panels must reference a variable defined in the templating list.
#   3. (Optional) Datasource UIDs differ from provisioned UID (warning only).
#      Set GRAFANA_DS_UID env var to enable.
set -euo pipefail

DASHBOARD_DIR="${1:-grafana/dashboards}"
EXPECTED_DS_UID="${GRAFANA_DS_UID:-}"
errors=0

shopt -s nullglob
files=("$DASHBOARD_DIR"/*.json)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "No dashboard JSON files found in $DASHBOARD_DIR"
  exit 0
fi

for f in "${files[@]}"; do
  echo "Linting: $f"

  # --- Check 1: query-type variables must use object format ---
  # In Grafana 10+ the Prometheus variable query field must be an object
  # (e.g. {"qryType":1,"query":"label_values(metric,label)"}).
  # A plain string silently produces no values.
  string_query_vars=$(jq -r '
    [.templating.list // [] | .[]
     | select(.type == "query" and (.query | type == "string"))
     | .name] | .[]
  ' "$f")

  for var in $string_query_vars; do
    echo "  ERROR: Variable \"$var\" uses plain-string query (old format)."
    echo "         Grafana 10+ requires object format, e.g. {\"qryType\": 1, \"query\": \"...\"}."
    errors=$((errors + 1))
  done

  # --- Check 2: repeat panels reference defined template variables ---
  defined_vars=$(jq -r '[.templating.list // [] | .[].name] | .[]' "$f")
  repeat_refs=$(jq -r '
    [.. | objects | select(has("repeat")) | .repeat
     | select(. != null and . != "")] | unique | .[]
  ' "$f")

  for rvar in $repeat_refs; do
    if ! echo "$defined_vars" | grep -qxF "$rvar"; then
      echo "  ERROR: Panel repeats on \"$rvar\" which is not defined in templating.list."
      errors=$((errors + 1))
    fi
  done

  # --- Check 3 (optional): datasource UIDs match expected value ---
  if [ -n "$EXPECTED_DS_UID" ]; then
    mismatched=$(jq -r --arg uid "$EXPECTED_DS_UID" '
      [.. | objects | .datasource? // empty
       | objects | select(has("uid") and .uid != $uid) | .uid]
      | unique | .[]
    ' "$f")

    for uid in $mismatched; do
      echo "  WARNING: Datasource UID \"$uid\" differs from expected \"$EXPECTED_DS_UID\"."
    done
  fi
done

echo ""
if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors error(s) found."
  exit 1
fi

echo "OK: All dashboards passed."
