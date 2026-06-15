# Minecraft Compatibility Strategy

Last reviewed: 2026-06-15

## Current Findings

VanillaCord is a bytecode patcher that tries to stay version-independent by
discovering obfuscated Minecraft server classes at patch time. It does not use
named Minecraft mappings or a per-version adapter table today.

Important implementation points:

- `Downloader` reads Mojang's `version_manifest_v2.json`, downloads a requested
  server jar, verifies Mojang's SHA-1 metadata, and patches it.
- `Patcher` distinguishes modern bundled server jars from older fat jars by
  checking `Bundler-Format` in `META-INF/MANIFEST.MF`.
- `SourceScanner` discovers patch targets by looking for stable string
  constants such as `Server console handler`, login hello diagnostics, payload
  size diagnostics, and handshake disconnect text.
- Login extension support has version-era branches for older mutable packet
  classes, constructor-based packets, and modern record/interface packet shapes.
- The README currently claims broad support through `1.21`, but Mojang's
  current release line has moved to calendar versions.

As of this review, Mojang's manifest reports:

- latest stable release: `26.1.2`
- latest snapshot/RC: `26.2-rc-2`
- current Minecraft/Paper server runtime line requires Java 25; run
  compatibility probes with JDK 25 even though VanillaCord currently emits Java
  21 bytecode for its own classes.

## Risk Areas

1. Discovery by string literals can break when Mojang changes diagnostics,
   translations, or control flow.
2. Login plugin message packet shapes have changed several times and are likely
   to change again.
3. The patchers fail late. Missing hook-point discovery is often observed as an
   injection or generated-helper failure instead of a clear compatibility
   report.
4. The release workflow builds a jar, but it has not historically gated releases
   on real Minecraft server jars.
5. The project lacks a generated support matrix, so documentation can drift from
   reality.

## Support Tiers

### Required Current

These must pass before a release is considered usable:

- latest Mojang stable release from `version_manifest_v2.json`
- latest Mojang snapshot/RC from `version_manifest_v2.json` when snapshot checks
  are enabled

### Required Supported

Representative versions that should stay supported until intentionally retired:

- `1.21.11`
- `1.20.6`
- `1.20.4`
- `1.19.4`
- `1.18.2`

### Best Effort Legacy

Older versions from the historical README claim. Failures should be reported but
should not block normal releases until a maintainer promotes a version back to
required support.

- `1.17.1`
- `1.16.5`
- `1.12.2`
- `1.8.9`
- `1.7.10`

## Execution Plan

1. Add a repeatable compatibility probe.
   - Build `artifacts/VanillaCord.jar`.
   - Resolve latest stable and latest snapshot from Mojang's manifest.
   - Patch each required version one at a time.
   - Patch best-effort versions and report failures without blocking.

2. Add conservative GitHub Actions compatibility checks.
   - Run manually with `workflow_dispatch`.
   - Do not run on a schedule by default to conserve GitHub Actions minutes on
     the free tier.
   - Upload the probe report as an artifact.

3. Improve diagnostics.
   - Add a source-discovery summary before patching.
   - Fail with explicit missing fields such as `startup`, `handshake`, `login`,
     `send`, `receive`, and `connection`.

4. Add adapter boundaries.
   - Keep heuristic discovery, but isolate version-era login extension behavior
     behind small adapter classes.
   - Avoid adding more large conditional branches inside translation emitters.

5. Gate releases.
   - The release workflow should run the compatibility probe for required
     current and required supported versions before uploading `VanillaCord.jar`.
   - Release notes should list the versions tested by CI.

6. Update documentation.
   - Replace broad README support claims with a tested support table generated
     from the compatibility workflow output.

## First Milestone

The first milestone is now started by adding:

- `scripts/check-minecraft-compatibility.sh`
- `scripts/Invoke-CompatibilityProbe.ps1`
- `.github/workflows/compatibility.yml`
- ASM `9.10.1` so the patcher can read current Java 25-era class files.

These provide real patching signal against current Mojang releases and the
maintained matrix before deeper code refactoring.

Local usage from Windows:

```powershell
$env:GITHUB_TOKEN = gh auth token
.\scripts\Invoke-CompatibilityProbe.ps1 -UseDocker
```

Use `-SkipSnapshot` when you only want stable release coverage:

```powershell
$env:GITHUB_TOKEN = gh auth token
.\scripts\Invoke-CompatibilityProbe.ps1 -UseDocker -SkipSnapshot
```

Use an empty local matrix for a lowest-cost smoke test of only the latest stable
release:

```powershell
$env:GITHUB_TOKEN = gh auth token
.\scripts\Invoke-CompatibilityProbe.ps1 -UseDocker -SkipSnapshot -RequiredSupported "" -BestEffortLegacy ""
```
