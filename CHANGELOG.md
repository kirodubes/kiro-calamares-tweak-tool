# Changelog

## 2026.06.03

### What Changed
First cut of the **Calamares Tweak Tool (CTT)** — a dev/expert PySide6 panel for the
Kiro live ISO that edits the Calamares encryption + bootloader settings before the
installer is launched, collapsing the "rebuild the ISO to test a one-line config change"
loop. v1 scope is the encryption ↔ bootloader pairing only.

Same-day refinements:
- Packaged as **`kiro-calamares-tweak-tool`** (kiro- prefix per the package-naming
  convention); the binary and `/usr/share` paths stay unprefixed `calamares-tweak-tool`.
- **Menu visibility:** dropped `NoDisplay=true` from the `.desktop` so the tool actually
  appears in the application menu (`Categories=System;Settings;Utility;`).
- **Correct launch command:** the Launch button now runs
  `/usr/bin/calamares_polkit -d -style kvantum` (the exact `cal-kiro.desktop` command,
  via the `calamares_polkit` wrapper = `pkexec --disable-internal-agent calamares`),
  instead of a bare `pkexec calamares` that skipped the wrapper and the KiroDark style.
- **Encryption is independent of the bootloader.** The bootloader still derives the LUKS
  *version* (luks1/luks2), but the encryption switch alone drives
  `enableLuksAutomatedPartitioning` — it's no longer auto-forced on when a bootloader is
  picked (that briefly left it stuck on `true`).
- **Visually-apparent encryption reminder** banner above the buttons so the setting isn't
  forgotten: amber when OFF ("Encryption is OFF — turn the switch on, or the installer
  won't offer to encrypt"), green when ON ("don't forget to tick 'Encrypt system' + set a
  passphrase in the installer").

### Technical Details
- **`confedit.py`** — `CalamaresConfig` reads/writes `bootloader.conf` (`efiBootLoader`)
  and `partition.conf` (`luksGeneration`, `enableLuksAutomatedPartitioning`) with
  comment-preserving regex line replacements, never a YAML round-trip. The v1 invariant
  lives here: `LUKS_FOR = {"grub": "luks1", "systemd-boot": "luks2"}`, so the LUKS
  generation is always derived from the bootloader — the unbootable LUKS2-on-stock-GRUB
  combo can't be expressed.
- **`main.py`** — PySide6 `Backend` QObject exposing bootloader / encryption / derived
  `luksGeneration` / writability to QML; `apply()` writes the files, `launchInstaller()`
  runs `pkexec calamares` (mirrors the live ISO's `calamares.desktop`). `--config-dir`
  (default `/etc/calamares`) and `--dev` (bundled sample) make it testable anywhere.
- **`Tweaker.qml`** — Kiro dark theme; bootloader radio, encryption switch, and a live
  LUKS readout that turns green (LUKS2/systemd-boot) or amber (LUKS1/GRUB) with the
  reason, surfacing the guard. Apply disabled when the config isn't writable.
- Toolkit is PySide6/Qt6 (matches kiro-keybindings): Calamares already pulls the Qt6
  runtime onto the live ISO, so CTT only adds the binding layer.
- Dev-hidden `.desktop` (`NoDisplay=true`) — kept off the default live desktop.

### Files Modified
- `usr/share/calamares-tweak-tool/confedit.py`
- `usr/share/calamares-tweak-tool/main.py`
- `usr/share/calamares-tweak-tool/Tweaker.qml`
- `usr/share/calamares-tweak-tool/sample/etc/calamares/modules/{partition,bootloader}.conf`
- `usr/bin/calamares-tweak-tool`
- `usr/share/applications/calamares-tweak-tool.desktop`
- `up.sh`, `setup.sh`, `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `LICENSE`
