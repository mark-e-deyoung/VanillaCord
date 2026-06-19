# Bridge Dependency

VanillaCord still depends on Bridge. It is not a historical leftover.

## How VanillaCord Uses Bridge

VanillaCord uses Bridge in three places:

| Use | Current dependency | Why it matters |
| --- | --- | --- |
| Build-time bytecode transformation | `net.ME1312.ASM:bridge-plugin` | Runs the Maven `bridge:bridge` goal during the VanillaCord build. |
| ASM helper APIs | `net.ME1312.ASM:bridge-asm` | Provides `HierarchyScanner`, `HierarchicalWriter`, `TypeMap`, `KnownType`, `LinkedVisitor`, and bytecode helper methods used by the patcher. |
| Bridge runtime API surface | `net.ME1312.ASM:bridge` | Provides `bridge.Invocation` and `bridge.Unchecked`, which are referenced by VanillaCord helper classes and processed by the Bridge plugin. |

Removing Bridge would be a deliberate refactor, not a dependency cleanup. A
replacement would need to recreate the hierarchy scanner, class writer behavior,
type-map helpers, and Bridge invocation transformations with plain ASM or a new
local abstraction.

## Fork Status

The maintained fork is:

```text
https://github.com/mark-e-deyoung/Bridge
```

It is a public fork of:

```text
https://github.com/ME1312/Bridge
```

The local workspace keeps Bridge as a sibling checkout:

```text
MineCraft/
  Bridge/
  VanillaCord/
```

VanillaCord resolves Bridge through Maven packages, not through source checkout.
The default owner in `pom.xml` is `mark-e-deyoung`, and CI can override it with
`BRIDGE_OWNER`.

## Submodule Decision

Do not add Bridge as a Git submodule of VanillaCord right now.

Reasons:

- VanillaCord consumes versioned Maven artifacts: `bridge`, `bridge-asm`, and
  `bridge-plugin`.
- GitHub Actions and local builds already need Maven package resolution, so a
  submodule would add a second dependency path rather than replacing the first.
- Submodules make clones, branch changes, and CI checkouts more fragile.
- Release reproducibility is better handled by pinning `BRIDGE_VERSION` to a
  published package version.

Use a sibling checkout for development and publish Bridge packages from the
Bridge fork when changes are needed. Then update VanillaCord by pinning
`BRIDGE_VERSION` or allowing CI to resolve the newest published Bridge package.

## Recommended Operating Model

1. Keep `mark-e-deyoung/Bridge` as the maintained fork.
2. Publish Bridge artifacts to GitHub Packages from that fork.
3. Use `BRIDGE_VERSION` to pin VanillaCord release builds.
4. Keep the local `Bridge/` checkout beside `VanillaCord/` for source work.
5. Avoid submodules unless VanillaCord is changed to build Bridge from source as
   a true multi-repository aggregate build.

