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

## Not a priority

Big refactors (splitting into modules, GUI, CI frameworks, config JSON, profiles) stay out unless there is a clear, simple need.
