#!/usr/bin/env bash
set -uo pipefail

JAR_PATH="${1:-artifacts/VanillaCord.jar}"
MANIFEST_URL="${MINECRAFT_MANIFEST_URL:-https://piston-meta.mojang.com/mc/game/version_manifest_v2.json}"
REQUIRED_SUPPORTED="${VANILLACORD_REQUIRED_SUPPORTED-1.21.11 1.20.6 1.20.4 1.19.4 1.18.2}"
BEST_EFFORT_LEGACY="${VANILLACORD_BEST_EFFORT_LEGACY-1.17.1 1.16.5 1.12.2 1.8.9 1.7.10}"
INCLUDE_SNAPSHOT="${VANILLACORD_INCLUDE_SNAPSHOT:-true}"
REPORT_PATH="${VANILLACORD_COMPAT_REPORT:-docs/minecraft-compatibility-report.md}"

if [[ "$REQUIRED_SUPPORTED" == "none" || "$REQUIRED_SUPPORTED" == "-" ]]; then
  REQUIRED_SUPPORTED=""
fi

if [[ "$BEST_EFFORT_LEGACY" == "none" || "$BEST_EFFORT_LEGACY" == "-" ]]; then
  BEST_EFFORT_LEGACY=""
fi

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
manifest_file="$(mktemp)"
trap 'rm -f "$manifest_file"' EXIT
printf '%s' "$manifest_json" > "$manifest_file"

latest_release="$(python3 - "$manifest_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    manifest = json.load(handle)
print(manifest["latest"]["release"])
PY
)"

latest_snapshot="$(python3 - "$manifest_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    manifest = json.load(handle)
print(manifest["latest"]["snapshot"])
PY
)"

version_exists() {
  local version="$1"
  python3 - "$manifest_file" "$version" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    manifest = json.load(handle)
version = sys.argv[2]
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
  mkdir -p "$(dirname "$REPORT_PATH")"
  echo "# VanillaCord Minecraft Compatibility Report"
  echo
  echo "- Generated: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
  echo "- Manifest: \`$MANIFEST_URL\`"
  echo "- Latest release: \`$latest_release\`"
  echo "- Latest snapshot: \`$latest_snapshot\`"
  echo "- Jar: \`$JAR_PATH\`"
  echo "- Required supported matrix: \`$REQUIRED_SUPPORTED\`"
  echo "- Best-effort legacy matrix: \`$BEST_EFFORT_LEGACY\`"
  echo "- Include snapshot/RC: \`$INCLUDE_SNAPSHOT\`"
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
