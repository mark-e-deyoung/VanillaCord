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
- `BRIDGE_OWNER` controls which GitHub owner to pull from (defaults to `mark-e-deyoung`).
- `BRIDGE_VERSION` pins a specific Bridge release; defaults to `0.1.0-SNAPSHOT` for reproducible builds. Set it to `LATEST` or another tag/SNAPSHOT when you intentionally want the newest.
- Example: `BRIDGE_OWNER=ME1312 BRIDGE_VERSION=0.1.0-SNAPSHOT.123 mvn -B verify`
- Compatibility probe: provide a release or snapshot server jar to sanity-check patch targets — `mvn -B verify -Dminecraft.serverJar=/path/to/server-<version>.jar`
