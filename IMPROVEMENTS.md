# Things we can improve

Keep WinPE Builder simple: one script, clear folders, few switches.

## Worth doing

1. **Use `packages.pe` automatically on `-Build`**  
   If the file is in the project folder, apply it without typing `-AddPackage packages.pe` every time.

2. **Warn if `startnet.cmd` is missing `wpeinit`**  
   Avoids a silent non-bootable image.

3. **Add a LICENSE file**  
   Makes reuse and forks clearer.

4. **Short CHANGELOG**  
   Note what changed between releases (keep it brief).

## Maybe later (only if it stays simple)

5. **USB confirm prompt** — show disk size/letter once more before format (skip when `-Quiet`).  
6. **Friendlier language errors** — if `-Language` packs are missing, list what the ADK actually has.  
7. **Skip bad drivers/updates with a warning** — same idea as missing packages today.

## Code tuning (same behavior, clearer / a bit faster)

Build time is mostly **DISM / copype / MakeWinPEMedia**. Script tweaks will not shrink that much — so only change places that are clearly wasteful or repeated.

| Change | Why | Risk |
|--------|-----|------|
| **Index `WinPE_OCs\*.cab` once** into a name→path map, reuse in `Add-OptionalPackages` | Today a missing exact path can re-scan the OC folder per package | Low |
| **Pass `$adk` into `Mount-BootImage`** instead of calling `Get-AdkInfo` again | Same data already from preflight | Low |
| **Check time zone once** | `-Build` validates, then `Set-ImageRegionalSettings` checks again | Low |
| **Buffer ADK/tool log lines** (write log in chunks, not every stderr line) | `Add-Content` per line is slow when tools are chatty | Low — keep console output as-is |
| **One small helper to resolve a `.cab`** (exact path, then case-insensitive map) | Removes duplicated lookup blocks; easier to read | Low |

**Leave alone:** splitting into modules, a GUI layer, parallel DISM, or heavy abstractions. Those cost readability for little gain.

## Not a priority

Big refactors (modules, GUI, CI frameworks, config JSON, profiles) stay out unless there is a clear, simple need.
