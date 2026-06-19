# VanillaCord
[![Build Status](https://github.com/mark-e-deyoung/VanillaCord/actions/workflows/build.yml/badge.svg)](https://github.com/mark-e-deyoung/VanillaCord/actions/workflows/build.yml)
[![Release Version](https://img.shields.io/github/release/mark-e-deyoung/VanillaCord/all.svg)](https://github.com/mark-e-deyoung/VanillaCord/releases)<br>

VanillaCord downloads and patches a vanilla Minecraft server, so proxies can connect to it with your choice of
[BungeeCord](https://www.spigotmc.org/wiki/bungeecord-ip-forwarding/),
[BungeeGuard](https://www.spigotmc.org/resources/bungeeguard.79601/), or
[Velocity](https://docs.papermc.io/velocity/security#velocity-modern-forwarding) IP forwarding enabled.
```
java -jar VanillaCord.jar <versions...>
```

## What VanillaCord does
VanillaCord is for vanilla Minecraft backend servers. It downloads the Mojang
server jar for each requested version, patches the jar, and writes the patched
server to `out/<version>.jar`. The patched server creates and reads a
`vanillacord.txt` file from its working directory.

Use VanillaCord when the backend server is vanilla. Do not install VanillaCord on
PaperMC. Paper has native Velocity forwarding support and should be configured
through Paper's own `config/paper-global.yml`.

## Downloads
*For Minecraft* 1.7, 1.8, 1.9, 1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.18, 1.19, 1.20, 1.21, snapshots, and pre-releases

<a href="https://github.com/mark-e-deyoung/VanillaCord/releases">
<pre>https://github.com/mark-e-deyoung/VanillaCord/releases</pre>
</a>

> Fork note: original work by the ME1312 team; this fork only adjusts the build/publish flow to use GitHub-hosted services and packages.

## Patching a vanilla server
Download `VanillaCord.jar`, then run it with one or more Minecraft versions:

```sh
java -jar VanillaCord.jar 26.2
```

The patched server jar is written to:

```text
out/26.2.jar
```

Run the patched jar from the server directory that contains `server.properties`,
`eula.txt`, and `vanillacord.txt`:

```sh
java -Xms2G -Xmx2G -jar out/26.2.jar --nogui
```

Current Minecraft server releases require Java 25. Older Minecraft versions may
require older Java runtimes, so pin both the Minecraft version and runtime when
maintaining legacy servers.

## Velocity modern forwarding
For a vanilla backend behind Velocity, use one shared secret in three places:

- Velocity proxy: `forwarding.secret`
- VanillaCord backend: `vanillacord.txt`
- CapRover deployment: `FORWARDING_SECRET`, when using this workspace's Docker images

Set Velocity to modern forwarding in `velocity.toml`:

```toml
online-mode = true
player-info-forwarding-mode = "modern"
forwarding-secret-file = "forwarding.secret"
```

Put the same secret in `forwarding.secret`:

```text
replace-with-a-long-random-secret
```

On the patched vanilla backend, set `server.properties` so players cannot bypass
the proxy identity flow:

```properties
online-mode=false
enforce-secure-profile=false
network-compression-threshold=-1
```

Then configure `vanillacord.txt` in the backend server working directory:

```properties
version = 2.0
forwarding = velocity
seecret = replace-with-a-long-random-secret
```

The key is intentionally spelled `seecret` because that is the historical
VanillaCord configuration name. Repeat `seecret = ...` on additional lines only
when rotating secrets or temporarily accepting multiple proxy secrets.

Velocity modern forwarding only protects identity data. Still firewall or
otherwise restrict backend server ports so players cannot connect directly to a
backend server.

## PaperMC backends
PaperMC does not use VanillaCord. For Paper behind Velocity, use Paper's native
Velocity forwarding instead:

```yaml
proxies:
  velocity:
    enabled: true
    online-mode: true
    secret: "replace-with-a-long-random-secret"
```

Also keep the same backend `server.properties` posture used for proxy-only
servers:

```properties
online-mode=false
enforce-secure-profile=false
network-compression-threshold=-1
```

The Velocity `forwarding.secret` value, Paper `proxies.velocity.secret`, and any
CapRover `FORWARDING_SECRET` value must match exactly. If they do not, Velocity
login will fail with an invalid forwarding data or forwarding secret error.

## CapRover workspace behavior
In this workspace, the vanilla server image downloads the latest VanillaCord
release and patches the selected vanilla server version at runtime. Set:

```text
MINECRAFT_SERVER_VERSION=26.2
FORWARDING_SECRET=replace-with-a-long-random-secret
SERVER_EULA=true
```

The Paper image does not use VanillaCord. It downloads Paper directly and should
use the same `FORWARDING_SECRET` as Velocity.

## Building
- Use JDK 25 for current Minecraft compatibility checks. The Maven build still emits Java 21 bytecode (`maven.compiler.release=21`) so the helper jar is not made Java 25-only unless that becomes necessary.
- Bridge artifacts are pulled from GitHub Packages at `https://maven.pkg.github.com/<owner>/Bridge`.
- Bridge is still required by the current patcher and build. See `docs/bridge-dependency.md` for the dependency and fork strategy.
- `BRIDGE_OWNER` controls which GitHub owner to pull from (defaults to the repository owner in CI, or `mark-e-deyoung` locally).
- `BRIDGE_VERSION` pins a specific Bridge build. GitHub builds publish run-numbered versions (e.g., `0.1.0-SNAPSHOT.123`); leave `BRIDGE_VERSION` unset/`LATEST` to auto-resolve the latest published version from GitHub Packages or pin it explicitly for reproducible builds.
- Example: `BRIDGE_OWNER=ME1312 BRIDGE_VERSION=$(./scripts/resolve-bridge-version.sh) mvn -B verify`
- Compatibility probe: `scripts/Invoke-CompatibilityProbe.ps1 -UseDocker` builds the jar and tests it against the current Mojang release, the optional snapshot/RC, required supported releases, and best-effort legacy releases.

## GitHub Packages auth (local)
- You need a PAT with `read:packages` for the owner hosting Bridge (and `write:packages` if you publish a new Bridge build).
- Keep auth in-repo to avoid host config issues: `export GH_CONFIG_DIR=$PWD/.gh && printf "%s\n" "$PAT" | gh auth login --with-token`
- When building locally, set `GITHUB_TOKEN=$PAT` so Maven (and `scripts/resolve-bridge-version.sh`) can read from `https://maven.pkg.github.com/${BRIDGE_OWNER}/Bridge`.

## GitHub Packages auth (CI)
- The workflow uses `BRIDGE_PACKAGES_TOKEN` (PAT with `read:packages` and `repo` if Bridge is private) and `BRIDGE_PACKAGES_USERNAME` if provided; otherwise it falls back to the default `GITHUB_TOKEN`/actor. Add the secret in repo settings if builds need to read Bridge from another private repo.

## Current fork status
- Latest validated release: `v2.4`.
- Last validated current Minecraft release: `26.2`.
- `v2.4` fixes current-version login listener discovery and preserves the full bundled server jar when patching 26.x releases.
- The CapRover vanilla image downloads the latest release asset from this fork and was validated with Minecraft `26.2`.
