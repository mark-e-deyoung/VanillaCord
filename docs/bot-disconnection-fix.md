# Bot Disconnection Fix — 2026-06-21

## Issue

Bots (and players) connecting through a **BungeeGuard**-configured VanillaCord backend server
were being silently disconnected with a `NullPointerException` when their BungeeCord proxy
did not include IP-forwarding properties in the handshake host field.

## Root Cause

**File:** `java/vanillacord/server/BungeeHelper.java`, method `parseHandshake()`

The control flow for setting the `PROPERTIES_KEY` Netty channel attribute had two gaps
when `seecrets != null` (BungeeGuard mode):

1. **`split.length == 3`** (no properties section in handshake): `PROPERTIES_KEY` was never
   set on the channel. The code had `if (seecrets == null) ... else if (split.length == 4)`,
   so the `split.length == 3` case with secrets fell through entirely.

2. **`split.length == 4` with empty properties JSON** (`properties.length == 0`): The
   `PROPERTIES_KEY` was only set inside the `if (properties.length != 0)` block, so
   empty arrays left the attribute unset.

When `PROPERTIES_KEY` is unset, `injectProfile()` calls `channel.attr(PROPERTIES_KEY).get()`
which returns `null`, and the for-each loop throws `NullPointerException`. This is caught
by `QuietException.show(e)` which terminates the connection with a hidden error.

### Incorrect code (before fix)

```java
if (seecrets == null) {
    channel.attr(PROPERTIES_KEY).set(
        (split.length == 3) ? new Property[0] : GSON.fromJson(split[3], Property[].class));
} else if (split.length == 4) {                          // <-- gap: split.length==3 with secrets
    Property[] properties = GSON.fromJson(split[3], Property[].class);
    if (properties.length != 0) {                         // <-- gap: empty properties array
        // ... filter, validate, set modified
        channel.attr(PROPERTIES_KEY).set(modified);
    }
}
```

### Fixed code (after fix)

```java
if (seecrets == null) {
    channel.attr(PROPERTIES_KEY).set(
        (split.length == 3) ? new Property[0] : GSON.fromJson(split[3], Property[].class));
} else {
    Property[] properties = (split.length == 4)
        ? GSON.fromJson(split[3], Property[].class)
        : new Property[0];                                // <-- handles split.length==3
    if (properties.length != 0) {
        // ... filter, validate, set modified
        channel.attr(PROPERTIES_KEY).set(modified);
    } else {
        channel.attr(PROPERTIES_KEY).set(properties);     // <-- handles empty array
    }
}
```

## Impact

- **Affected mode:** BungeeGuard forwarding only (`forwarding = bungeeguard` in `vanillacord.txt`)
- **Not affected:** BungeeCord (no secrets), Velocity (different code path)
- **Symptom:** Silent disconnection with no visible error to the player/bot
- **Server log:** "VanillaCord has disconnected a player with the following error message:"
  followed by a NullPointerException (hidden by QuietException)

## VelocityHelper Review

The `VelocityHelper.completeTransaction()` was also reviewed. All failure paths (invalid
transaction ID, null data, bad HMAC signature) correctly throw `QuietException` which
terminates the Netty channel. The `LOGIN_KEY` attribute is properly cleaned up in a
`finally` block after the `hello()` call. No fix needed.

## Next Steps

1. **Build and test:** Compile with `mvn -B verify` (requires JDK 25 + `GITHUB_TOKEN`)
2. **Run compatibility probe:** `./scripts/Invoke-CompatibilityProbe.ps1 -UseDocker`
3. **Deploy:** The patched `artifacts/VanillaCord.jar` replaces the previous release
4. **Verify:** Connect a bot through BungeeGuard without properties — should no longer
   see NPE disconnection
