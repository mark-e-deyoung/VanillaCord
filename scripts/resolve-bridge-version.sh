#!/usr/bin/env bash
set -euo pipefail

# Resolve the latest published Bridge version from GitHub Packages.
# Requires a token with read:packages; prefers BRIDGE_OWNER, then GITHUB_REPOSITORY_OWNER, then default fork owner.

ROOT="${BASH_SOURCE%/*}/.."
cd "$ROOT"

BRIDGE_OWNER="${BRIDGE_OWNER:-${GITHUB_REPOSITORY_OWNER:-mark-e-deyoung}}"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
ACTOR="${GITHUB_ACTOR:-token}"

if [[ -z "${TOKEN}" ]]; then
  echo "GITHUB_TOKEN (or GH_TOKEN) is required to read Bridge artifacts from GitHub Packages." >&2
  exit 1
fi

META_URL="https://maven.pkg.github.com/${BRIDGE_OWNER}/Bridge/net/ME1312/ASM/bridge/maven-metadata.xml"

xml="$(curl -fsSL -u "${ACTOR}:${TOKEN}" "${META_URL}")"

# Pick the <release>, <latest>, or last listed <version>.
version="$(
  XML_CONTENT="$xml" python - <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

xml = os.environ["XML_CONTENT"]
root = ET.fromstring(xml)
for path in ("./versioning/release", "./versioning/latest"):
    node = root.find(path)
    if node is not None and node.text and node.text.strip():
        print(node.text.strip())
        sys.exit(0)

versions = [node.text.strip() for node in root.findall("./versioning/versions/version") if node.text and node.text.strip()]
if not versions:
    sys.exit("No Bridge versions found in metadata")

print(versions[-1])
PY
)"

echo "${version}"
