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

---

#  Quick Start

1. Connect your display panel or programmable speaker to the circuit network.
2. In a display message or alert message, type:

```
[ ]

```

#  Placeholders

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

#  Formatting Mode Overrides

| Directive | Meaning |
|-----------|----------|
| `[exact]` | Force exact number formatting |
| `[si]` | Force condensed SI formatting (k, M, G…) |

---

#  Modifiers (stackable, only affect the following placeholder)

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

#  Colouring Counts

Automatic (green for positive counts, red for negative, yellow for zero):

```
[colour][sign][rate]/s
```

Manual:

```
[color=orange]Speed: [rate] km/s[/color]
```

UK spelling supported:

```
[colour=orange]Speed: [rate] km/s[/colour]
```

---

#  Compatibility

- Requires **Factorio 2.0+**
- Space Age compatible (not required)

---

#  Changelog

## 1.0.0

Initial stable release.
