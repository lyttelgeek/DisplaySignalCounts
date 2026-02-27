# Changelog

All notable changes to this project will be documented in this file.

This project follows semantic versioning (MAJOR.MINOR.PATCH).

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
