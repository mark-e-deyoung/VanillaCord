#!/usr/bin/env bash
set -uo pipefail

JAR_PATH="${1:-artifacts/VanillaCord.jar}"
MANIFEST_URL="${MINECRAFT_MANIFEST_URL:-https://piston-meta.mojang.com/mc/game/version_manifest_v2.json}"
REQUIRED_SUPPORTED="${VANILLACORD_REQUIRED_SUPPORTED:-1.21.11 1.20.6 1.20.4 1.19.4 1.18.2}"
BEST_EFFORT_LEGACY="${VANILLACORD_BEST_EFFORT_LEGACY:-1.17.1 1.16.5 1.12.2 1.8.9 1.7.10}"
INCLUDE_SNAPSHOT="${VANILLACORD_INCLUDE_SNAPSHOT:-true}"
REPORT_PATH="${VANILLACORD_COMPAT_REPORT:-compatibility-report.md}"

if [[ ! -f "$JAR_PATH" ]]; then
  echo "VanillaCord jar not found: $JAR_PATH" >&2
  exit 1
fi

manifest_json="$(python3 - "$MANIFEST_URL" <<'PY'
import sys
from urllib.request import urlopen

with urlopen(sys.argv[1], timeout=30) as response:
    sys.stdout.write(response.read().decode("utf-8"))
PY
)"
export MANIFEST_JSON="$manifest_json"

latest_release="$(python3 - <<'PY'
import json, os
manifest = json.loads(os.environ["MANIFEST_JSON"])
print(manifest["latest"]["release"])
PY
)"

latest_snapshot="$(python3 - <<'PY'
import json, os
manifest = json.loads(os.environ["MANIFEST_JSON"])
print(manifest["latest"]["snapshot"])
PY
)"

version_exists() {
  local version="$1"
  python3 - "$version" <<'PY'
import json, os, sys
version = sys.argv[1]
manifest = json.loads(os.environ["MANIFEST_JSON"])
sys.exit(0 if any(item["id"] == version for item in manifest["versions"]) else 1)
PY
}

append_unique() {
  local list="$1"
  local value="$2"
  if [[ " $list " == *" $value "* ]]; then
    printf '%s\n' "$list"
  else
    printf '%s %s\n' "$list" "$value"
  fi
}

required_current="$latest_release"
if [[ "$INCLUDE_SNAPSHOT" == "true" && -n "$latest_snapshot" && "$latest_snapshot" != "$latest_release" ]]; then
  required_current="$(append_unique "$required_current" "$latest_snapshot")"
fi

required_versions="$required_current"
for version in $REQUIRED_SUPPORTED; do
  required_versions="$(append_unique "$required_versions" "$version")"
done

best_effort_versions=""
for version in $BEST_EFFORT_LEGACY; do
  best_effort_versions="$(append_unique "$best_effort_versions" "$version")"
done

{
  echo "# VanillaCord Minecraft Compatibility Report"
  echo
  echo "- Manifest: \`$MANIFEST_URL\`"
  echo "- Latest release: \`$latest_release\`"
  echo "- Latest snapshot: \`$latest_snapshot\`"
  echo "- Jar: \`$JAR_PATH\`"
  echo
  echo "| Tier | Version | Result |"
  echo "| --- | --- | --- |"
} > "$REPORT_PATH"

required_failed=0
best_effort_failed=0

run_probe() {
  local tier="$1"
  local version="$2"
  local required="$3"

  if ! version_exists "$version"; then
    echo "| $tier | \`$version\` | missing from Mojang manifest |" >> "$REPORT_PATH"
    if [[ "$required" == "true" ]]; then
      required_failed=1
    else
      best_effort_failed=1
    fi
    return
  fi

  echo "Patching Minecraft $version ($tier)"
  if java -jar "$JAR_PATH" "$version"; then
    echo "| $tier | \`$version\` | pass |" >> "$REPORT_PATH"
  else
    echo "| $tier | \`$version\` | fail |" >> "$REPORT_PATH"
    if [[ "$required" == "true" ]]; then
      required_failed=1
    else
      best_effort_failed=1
    fi
  fi
}

for version in $required_versions; do
  run_probe "required" "$version" "true"
done

for version in $best_effort_versions; do
  run_probe "best-effort" "$version" "false"
done

echo
cat "$REPORT_PATH"

if [[ "$best_effort_failed" -ne 0 ]]; then
  echo "One or more best-effort legacy versions failed. See $REPORT_PATH." >&2
fi

if [[ "$required_failed" -ne 0 ]]; then
  echo "One or more required Minecraft versions failed. See $REPORT_PATH." >&2
  exit 1
fi
