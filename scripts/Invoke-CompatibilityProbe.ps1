param(
    [string]$BridgeOwner = $env:BRIDGE_OWNER,
    [string]$BridgeVersion = $env:BRIDGE_VERSION,
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$RequiredSupported = $env:VANILLACORD_REQUIRED_SUPPORTED,
    [string]$BestEffortLegacy = $env:VANILLACORD_BEST_EFFORT_LEGACY,
    [string]$ReportPath = $env:VANILLACORD_COMPAT_REPORT,
    [switch]$SkipSnapshot,
    [switch]$UseDocker
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($BridgeOwner)) {
    $BridgeOwner = "mark-e-deyoung"
}

if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if ($gh) {
        $GitHubToken = (& gh auth token).Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
    throw "Set GITHUB_TOKEN or authenticate gh. The token needs read:packages for Bridge."
}

$repo = Resolve-Path (Join-Path $PSScriptRoot "..")
$includeSnapshot = if ($SkipSnapshot) { "false" } else { "true" }
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = "docs/minecraft-compatibility-report.md"
}

function Get-BashPath {
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if ($bash -and $bash.Source -notlike "*WindowsApps*" -and $bash.Source -notlike "*system32*") {
        return $bash.Source
    }

    $gitBash = Get-Command "C:\Program Files\Git\bin\bash.exe" -ErrorAction SilentlyContinue
    if ($gitBash) {
        return $gitBash.Source
    }

    if ($bash) {
        return $bash.Source
    }

    throw "bash was not found. Install Git for Windows, WSL, or rerun with -UseDocker."
}

function Invoke-LocalProbe {
    $mvn = Get-Command mvn -ErrorAction SilentlyContinue
    if (-not $mvn) {
        throw "mvn was not found. Install Maven or rerun with -UseDocker."
    }

    if ([string]::IsNullOrWhiteSpace($BridgeVersion)) {
        $env:BRIDGE_OWNER = $BridgeOwner
        $env:GITHUB_TOKEN = $GitHubToken
        $bashPath = Get-BashPath
        $BridgeVersion = (& $bashPath ./scripts/resolve-bridge-version.sh).Trim()
    }

    & mvn -B verify "-Dbridge.owner=$BridgeOwner" "-Dbridge.version=$BridgeVersion"
    if ($LASTEXITCODE -ne 0) {
        throw "Maven build failed with exit code $LASTEXITCODE"
    }

    $env:VANILLACORD_INCLUDE_SNAPSHOT = $includeSnapshot
    if ($null -ne $RequiredSupported) {
        $env:VANILLACORD_REQUIRED_SUPPORTED = $RequiredSupported
    }
    if ($null -ne $BestEffortLegacy) {
        $env:VANILLACORD_BEST_EFFORT_LEGACY = $BestEffortLegacy
    }
    $env:VANILLACORD_COMPAT_REPORT = $ReportPath
    $bashPath = Get-BashPath
    & $bashPath ./scripts/check-minecraft-compatibility.sh artifacts/VanillaCord.jar
    if ($LASTEXITCODE -ne 0) {
        throw "Compatibility probe failed with exit code $LASTEXITCODE"
    }
}

function Invoke-DockerProbe {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        throw "docker was not found."
    }

    $bridgeVersionExport = ""
    if (-not [string]::IsNullOrWhiteSpace($BridgeVersion)) {
        $bridgeVersionExport = "export BRIDGE_VERSION='$BridgeVersion';"
    }

    $script = @"
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends bash ca-certificates curl git python3 python-is-python3 ripgrep
mkdir -p /tmp/vanillacord-scripts
tr -d '\r' < ./scripts/resolve-bridge-version.sh > /tmp/vanillacord-scripts/resolve-bridge-version.sh
tr -d '\r' < ./scripts/check-minecraft-compatibility.sh > /tmp/vanillacord-scripts/check-minecraft-compatibility.sh
chmod +x /tmp/vanillacord-scripts/*.sh
export BRIDGE_OWNER='$BridgeOwner'
export BRIDGE_VERSION='$BridgeVersion'
: "`${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
mkdir -p "`$HOME/.m2"
cat > "`$HOME/.m2/settings.xml" <<'MAVEN_SETTINGS'
<settings>
  <servers>
    <server>
      <id>bridge-github</id>
      <username>mark-e-deyoung</username>
      <password>__GITHUB_TOKEN__</password>
    </server>
  </servers>
</settings>
MAVEN_SETTINGS
python3 - <<'PY'
from pathlib import Path
import os
path = Path.home() / ".m2" / "settings.xml"
path.write_text(path.read_text().replace("__GITHUB_TOKEN__", os.environ["GITHUB_TOKEN"]))
PY
$bridgeVersionExport
if [ -z "`$BRIDGE_VERSION" ]; then
  BRIDGE_VERSION="`$(bash /tmp/vanillacord-scripts/resolve-bridge-version.sh)"
  export BRIDGE_VERSION
fi
mvn -B verify -Dbridge.owner="`$BRIDGE_OWNER" -Dbridge.version="`$BRIDGE_VERSION"
export VANILLACORD_INCLUDE_SNAPSHOT='$includeSnapshot'
export VANILLACORD_COMPAT_REPORT='$ReportPath'
bash /tmp/vanillacord-scripts/check-minecraft-compatibility.sh artifacts/VanillaCord.jar
"@

    $dockerScript = Join-Path $repo ".vanillacord-compat-docker.sh"
    try {
        Set-Content -LiteralPath $dockerScript -Value $script -NoNewline -Encoding ASCII

        & docker run --rm `
            -v "${repo}:/workspace" `
            -w /workspace `
            -e "BRIDGE_OWNER=$BridgeOwner" `
            -e "GITHUB_TOKEN=$GitHubToken" `
            -e "VANILLACORD_INCLUDE_SNAPSHOT=$includeSnapshot" `
            -e "VANILLACORD_COMPAT_REPORT=$ReportPath" `
            -e "VANILLACORD_REQUIRED_SUPPORTED=$RequiredSupported" `
            -e "VANILLACORD_BEST_EFFORT_LEGACY=$BestEffortLegacy" `
            maven:3.9-eclipse-temurin-25 `
            bash ./.vanillacord-compat-docker.sh
    } finally {
        Remove-Item -LiteralPath $dockerScript -Force -ErrorAction SilentlyContinue
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Docker compatibility probe failed with exit code $LASTEXITCODE"
    }
}

if ($UseDocker) {
    Invoke-DockerProbe
} else {
    Invoke-LocalProbe
}
