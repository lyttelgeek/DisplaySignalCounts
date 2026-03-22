#  Display Signal Counts

**Display Signal Counts** is a UPS-efficient Factorio 2.0 mod that lets you insert live circuit network signal values directly into:

-  **Display panel messages**
-  **Programmable speaker alert messages**

It supports:

- Multiple placeholders per message
- Inline signal selection (including quality)
- Useful transforms (`avg`, `rate`, `delta`, `min`, `max`, `abs`)
- Rounding and formatting helpers
- Automatic or manual colour rendering
- Seamless integration with icons and text
- Full support for both **color** and **colour** spellings 😉

Counts are always sourced from the **incoming circuit network**.
The panel’s displayed icon or conditional icon state does **not** affect the value shown.
If no signal is specified, placeholders evaluate to 0 by design.
Included global setting option for default count display: exact or condensed SI (k, M, G etc.)

---

##  Quick Start

1. Connect your display panel or programmable speaker to the circuit network.
2. Set a signal condition.
3. In a display message or alert message, enter a placeholder:

```
[ ]
```

---

##  Placeholders

| Placeholder | Meaning |
|-------------|----------|
| `[ ]` | Current value |
| `[abs]` | Absolute value |
| `[avg]` | Moving average |
| `[delta]` | Change since last update |
| `[rate]` | Change per second |
| `[min]` | Minimum over rolling window |
| `[max]` | Maximum over rolling window |

---

##  Formatting Mode Overrides (only affects following placeholder)

| Directive | Meaning |
|-----------|----------|
| `[exact]` | Force exact number formatting |
| `[si]` | Force condensed SI formatting (k, M, G…) |

---

##  Modifiers (stackable, only affects the following placeholder)

| Modifier | Meaning |
|----------|----------|
| `[prec N]` | Set decimal places |
| `[clamp A B]` | Clamp into range |
| `[floor]` | Round down |
| `[ceil]` | Round up |
| `[round]` | Round to nearest whole |
| `[sign]` | Adds + / − / ± prefix |
| `[pct]` | Clamp 0–100 and append % |

---

##  Manual inline signal selection (affects all following placeholders until another '[sig ...]' is used or is reset with '[sig]')

Display a specific signal count other than the default first condition. (If no quality is defined, common is assumed):

```
[sig <type> <name> <quality>][ ]
```

---

##  Colouring Counts

Automatic colouring (green for positive counts, red for negative, yellow for zero):

```
[color][ ]
```

Apply colour deadzone to prevent automatic colour flickering with counts such as [delta] (treats values <0.01 as 0): 

```
[dz 0.01][color][delta]
```

Manual colouring:

```
[color=orange][ ][/color]
[color=255,255,0][ ][/color]
```

UK spelling supported:

```
[colour][ ]
[colour=orange][ ][/colour]
[colour=255,255,0][ ][/colour]
```

---

##  Compatibility

- Requires **Factorio 2.0+**
- Space Age compatible (not required)

---

##  Current Version

[v1.0.0 Initial Standalone Release](https://github.com/lyttelgeek/DisplaySignalCounts/releases/tag/1.0.0-Initial_Release)

---
