# VanillaCord
[![Build Status](https://dev.me1312.net/jenkins/job/VanillaCord/badge/icon)](https://dev.me1312.net/jenkins/job/VanillaCord/)
[![Release Verison](https://img.shields.io/github/release/ME1312/VanillaCord/all.svg)](https://github.com/ME1312/VanillaCord/releases)<br>

VanillaCord downloads and patches a vanilla Minecraft server, so proxies can connect to it with your choice of
[BungeeCord](https://www.spigotmc.org/wiki/bungeecord-ip-forwarding/),
[BungeeGuard](https://www.spigotmc.org/resources/bungeeguard.79601/), or
[Velocity](https://docs.papermc.io/velocity/security#velocity-modern-forwarding) IP forwarding enabled.
```
java -jar VanillaCord.jar <versions...>
```

## Downloads
*For Minecraft* 1.7, 1.8, 1.9, 1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.18, 1.19, 1.20, 1.21, snapshots, and pre-releases

<a href="https://dev.me1312.net/jenkins/job/VanillaCord">
<pre>https://dev.me1312.net/jenkins/job/VanillaCord</pre>
</a>

> Fork note: original work by the ME1312 team; this fork only adjusts the build/publish flow to use GitHub-hosted services and packages.

## Building
- Requires Java 21+ (Bridge artifacts target Java 21).
- Bridge artifacts are pulled from GitHub Packages at `https://maven.pkg.github.com/<owner>/Bridge`.
- `BRIDGE_OWNER` controls which GitHub owner to pull from (defaults to the repository owner in CI, or `mark-e-deyoung` locally).
- `BRIDGE_VERSION` pins a specific Bridge build. GitHub builds publish run-numbered versions (e.g., `0.1.0-SNAPSHOT.123`); leave `BRIDGE_VERSION` unset/`LATEST` to auto-resolve the latest published version from GitHub Packages or pin it explicitly for reproducible builds.
- Example: `BRIDGE_OWNER=ME1312 BRIDGE_VERSION=$(./scripts/resolve-bridge-version.sh) mvn -B verify`
- Compatibility probe: provide a release or snapshot server jar to sanity-check patch targets — `mvn -B verify -Dminecraft.serverJar=/path/to/server-<version>.jar`

## GitHub Packages auth (local)
- You need a PAT with `read:packages` for the owner hosting Bridge (and `write:packages` if you publish a new Bridge build).
- Keep auth in-repo to avoid host config issues: `export GH_CONFIG_DIR=$PWD/.gh && printf "%s\n" "$PAT" | gh auth login --with-token`
- When building locally, set `GITHUB_TOKEN=$PAT` so Maven (and `scripts/resolve-bridge-version.sh`) can read from `https://maven.pkg.github.com/${BRIDGE_OWNER}/Bridge`.
