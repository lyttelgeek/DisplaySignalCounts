#  Display Signal Counts

**Display Signal Counts** is a UPS-efficient Factorio 2.0 mod that lets
you insert live circuit network signal values directly into:

-    **Display panel messages**
-    **Programmable speaker alert messages**

It supports:

-   Multiple placeholders per message
-   Inline signal selection (including quality)
-   Useful transforms (`avg`, `rate`, `delta`, `min`, `max`, `abs`)
-   Rounding and formatting helpers
-   Automatic or manual colour rendering
-   Seamless integration with icons and text
-   Full support for both **color** and **colour** spellings😉

Counts are always sourced from the **incoming circuit network**.
The panel's displayed icon or conditional icon state does **not** affect
the value shown.

Build fully custom dashboards, telemetry panels, status boards, and
highly informative alerts.

------------------------------------------------------------------------

#  Quick Start

1.  Connect your display panel or programmable speaker to the circuit
    network.
2.  In a display message or alert message, type:

```{=html}
<!-- -->
```
    [ ]

That inserts the default signal value.

Example:

    Speed: [prec 1][rate] km/s   Δ: [delta]

------------------------------------------------------------------------

#  Default Signal Selection

If you do not explicitly select a signal with `[sig ...]`, the mod uses:

-   **Display panels** → `condition.first_signal`
-   **Programmable speakers** → alert icon signal, otherwise the
    speaker's condition first signal

If nothing specifies a signal, the placeholder evaluates to **0** (by
design).

------------------------------------------------------------------------

#  Placeholders

  Placeholder   Meaning
  ------------- -----------------------------
  `[ ]`         Current value
  `[abs]`       Absolute value
  `[avg]`       Moving average
  `[delta]`     Change since last update
  `[rate]`      Change per second
  `[min]`       Minimum over rolling window
  `[max]`       Maximum over rolling window

------------------------------------------------------------------------

#  Formatting Mode Overrides

  Directive   Meaning
  ----------- --------------------------------------------
  `[exact]`   Force exact number formatting
  `[si]`      Force condensed SI formatting (k, M, G...)

The default format comes from the mod's global setting.

------------------------------------------------------------------------

#  Signal Selection (Inline)

    [sig <type> <name> <quality>]

Examples:

    [sig virtual signal-A][ ]
    [sig item iron-plate][ ]
    [sig item iron-plate legendary][ ]
    [sig fluid water][ ]

Quality is optional.
Return to the message's default signal with:

    [sig]

------------------------------------------------------------------------

#  Modifiers

Modifiers apply **only to the immediately following placeholder** and
can stack.

  Modifier        Meaning
  --------------- ---------------------------
  `[prec N]`      Set decimal places
  `[clamp A B]`   Clamp into range
  `[floor]`       Round down
  `[ceil]`        Round up
  `[round]`       Round to nearest whole
  `[sign]`        Adds + / − / ± prefix
  `[pct]`         Clamp 0--100 and append %

Example:

    [clamp 0 100][pct][ ]

------------------------------------------------------------------------

#  Colouring Counts

## Automatic Colouring

    [colour][sign][rate]/s

Optional deadzone:

    [dz 0.01][colour][delta]

Green → positive
Red → negative
Yellow → \~zero

## Manual Rich Text Colouring

    [color=orange]Speed: [rate] km/s[/color]

UK spelling is supported and translated automatically:

    [colour=orange]Speed: [rate] km/s[/colour]

------------------------------------------------------------------------

#  Examples

### Dashboard Panel

    [virtual-signal=signal-speed]    v:[prec 1][ ]    avg:[prec 1][avg]    Δ:[sign][delta]    rate:[colour][sign][prec 2][rate]/s

### Speaker Alert

    ALERT: power trending [colour][sign][rate]/s (now [ ])

### Percentage Clamp

    Accumulator: [pct][ ]

------------------------------------------------------------------------

#  Compatibility

-   Requires **Factorio 2.0+**
-   Fully compatible with **Space Age**
-   Space Age not required

------------------------------------------------------------------------

#  Performance

-   Lightweight per-entity updates
-   Template preservation
-   Edit grace window
-   Platform-aware rescanning

------------------------------------------------------------------------

#  Links

GitHub (source + releases):
https://github.com/lyttelgeek/DisplaySignalCounts

------------------------------------------------------------------------

# 📦 Changelog

## 1.0.0 --- Initial Stable Release

-   Display panel support
-   Programmable speaker support
-   Multiple placeholders per message
-   Inline signal selection (`[sig]`)
-   Transforms: `abs`, `avg`, `delta`, `rate`, `min`, `max`
-   Formatting helpers: `prec`, `clamp`, `floor`, `ceil`, `round`
-   Formatting overrides: `si`, `exact`
-   `[sign]` prefix helper (+ / − / ±)
-   `[pct]` helper
-   Automatic colouring (`[color]` / `[colour]`)
-   Deadzone support (`[dz]`)
-   Manual rich text colour compatibility
-   UK spelling support
-   Space Age compatibility
-   Template preservation + edit grace window
-   UPS-efficient architecture
