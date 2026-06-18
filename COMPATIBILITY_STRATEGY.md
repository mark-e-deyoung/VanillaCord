# Minecraft Compatibility Strategy

Last reviewed: 2026-06-18

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

As of the latest deployment validation, Mojang's manifest reports:

- latest stable release: `26.2`
- latest snapshot/RC: not rechecked during the final deployment pass
- current Minecraft/Paper server runtime line requires Java 25; run
  compatibility probes with JDK 25 even though VanillaCord currently emits Java
  21 bytecode for its own classes.

Additional finding from the 2026-06-16 production fix:

- VanillaCord `v2.3` could read Java 25-era classes but failed while patching
  current 26.x login flow. The partially written bundled jar was cached by the
  vanilla server container and later failed at boot with a missing
  `net/minecraft/server/permissions/PermissionSet` class.
- The scanner was selecting `handleLoginAcknowledgement` because the string
  `Unexpected login acknowledgement packet` matched the loose
  `unexpected login` heuristic. `v2.4` excludes acknowledgement text from login
  hello discovery and handles the current offline-profile call shape.
- The vanilla CapRover image now deletes partial `out/<version>.jar` files on
  failed VanillaCord installs to avoid reusing broken output.

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

## Current Release Status

- `v2.4` is the current release and has a GitHub Actions-published
  `VanillaCord.jar` asset.
- Local validation patched Minecraft `26.1.2` successfully after the fix and
  confirmed the nested bundled server jar retained `PermissionSet.class` and
  VanillaCord helper classes.
- Production validation then ran Minecraft `26.2` through the CapRover vanilla
  image successfully.
- Next release hardening should gate releases on the compatibility probe instead
  of relying on manual local and production validation.

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
