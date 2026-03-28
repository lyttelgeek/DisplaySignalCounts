# Changelog

## [1.0.2] - Internal cleanup and save/reload fix

### Fixed
- Displays silently stopping after a save/reload cycle — caused by the update loop not being re-registered on `on_load`
- Space Age detection now checks active mods directly rather than relying solely on platform surface name heuristics, so detection works before the player has launched a rocket

### Changed
- Update interval reduced from 30 ticks to 2 ticks for more responsive live panels
- Settings changes at runtime now correctly propagate to the update loop without requiring a reload
- All internal storage keys and setting names updated from the `sigd` prefix (inherited from Signal Display) to `dsc`
- Existing saves are automatically migrated on load, no data is lost
- Removed development log spam

---


## [1.0.1] - Inline selector hotfix

### Fixes
- Fixed inline signal selector breaking when WDP is not installed

---

## [1.0.0] - Initial Stable Release

### Added
- Support for Display Panels
- Support for Programmable Speakers
- Multiple placeholders per message
- Inline signal selection via `[sig <type> <name> <quality>]`
- Signal quality support
- Derived value placeholders:
  - `[abs]`
  - `[avg]`
  - `[delta]`
  - `[rate]`
  - `[min]`
  - `[max]`
- Formatting helpers:
  - `[prec N]`
  - `[clamp A B]`
  - `[floor]`
  - `[ceil]`
  - `[round]`
- Formatting overrides:
  - `[exact]`
  - `[si]`
- `[sign]` helper (+ / − / ± prefix support)
- `[pct]` helper (clamp 0–100 and append %)
- Automatic colouring via `[color]` / `[colour]`
- Colour deadzone support via `[dz]`
- Manual rich text colour support
- UK spelling support for colour directives and tags
- Template preservation system
- Edit grace window to prevent overwriting manual edits
- Space Age compatibility (not required)
- Platform-aware rescanning
- UPS-efficient update architecture

### Notes
- Counts are sourced strictly from the incoming circuit network.
- Panel icon state does not affect value calculation.
- If no signal is specified, placeholders evaluate to 0 by design.

---

Future versions will increment:
- PATCH for bug fixes
- MINOR for new features
- MAJOR for breaking changes
