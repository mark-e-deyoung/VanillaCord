# VanillaCord Compatibility

VanillaCord compatibility is tested by patching real Mojang server jars with the
same script in every environment:

```sh
scripts/check-minecraft-compatibility.sh artifacts/VanillaCord.jar
```

The GitHub Actions workflow, local PowerShell wrapper, Docker wrapper, and any
other CI/CD system should call that script rather than duplicating matrix logic.

## Tested Range

The default matrix is defined by environment variables in
`scripts/check-minecraft-compatibility.sh`.

| Tier | Versions | Blocks release |
| --- | --- | --- |
| Current stable | Latest Mojang stable release from `version_manifest_v2.json` | yes |
| Current snapshot/RC | Latest Mojang snapshot from `version_manifest_v2.json`, when enabled | yes |
| Required supported | `1.21.11 1.20.6 1.20.4 1.19.4 1.18.2` | yes |
| Best-effort legacy | `1.17.1 1.16.5 1.12.2 1.8.9 1.7.10` | no |

Override the matrix with:

```sh
VANILLACORD_INCLUDE_SNAPSHOT=false
VANILLACORD_REQUIRED_SUPPORTED="1.21.11 1.20.6"
VANILLACORD_BEST_EFFORT_LEGACY="1.16.5 1.12.2"
VANILLACORD_COMPAT_REPORT=docs/minecraft-compatibility-report.md
```

Set `VANILLACORD_REQUIRED_SUPPORTED` or `VANILLACORD_BEST_EFFORT_LEGACY` to an
empty string, `none`, or `-` to clear that tier for a smoke run.

## Reports

The generated report path defaults to:

```text
docs/minecraft-compatibility-report.md
```

GitHub Actions uploads that file as an artifact and appends it to the workflow
summary. Local runs write the same file, so a maintainer can commit a generated
report when they want repository documentation to reflect a specific validation
run.

## Local Run

On Windows, use the wrapper. `-UseDocker` is the most reproducible path because
it supplies JDK 25, Maven, Python, and Bash inside the container:

```powershell
$env:GITHUB_TOKEN = (gh auth token).Trim()
.\scripts\Invoke-CompatibilityProbe.ps1 -UseDocker
```

For a lower-cost smoke test:

```powershell
$env:GITHUB_TOKEN = (gh auth token).Trim()
.\scripts\Invoke-CompatibilityProbe.ps1 -UseDocker -SkipSnapshot -RequiredSupported "" -BestEffortLegacy ""
```

For a lower-cost GitHub Actions dispatch, set `include_snapshot=false` and set
both version-list inputs to `none`.

## Other CI/CD Systems

Set `GITHUB_TOKEN` with `read:packages`, build `artifacts/VanillaCord.jar`, then
run:

```sh
export BRIDGE_OWNER="${BRIDGE_OWNER:-mark-e-deyoung}"
export VANILLACORD_COMPAT_REPORT="${VANILLACORD_COMPAT_REPORT:-docs/minecraft-compatibility-report.md}"
scripts/check-minecraft-compatibility.sh artifacts/VanillaCord.jar
```
