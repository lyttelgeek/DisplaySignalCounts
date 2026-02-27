Display Signal Counts

Display Signal Counts is a very UPS-efficient mod that lets you insert circuit network signal values into:

-Display panel messages

-Programmable speaker alert messages


It supports multiple placeholders per message, inline signal selection (including optional quality), a bunch of useful transforms (avg/rate/delta/min/max/abs), rounding helpers, and formatting commands.

Counts are always sourced from the incoming circuit network — the panel’s displayed icon / conditional icon state does not affect the value shown. Build fully custom dashboards, status boards, and highly informative alerts. The mod supports the correct spelling of “colour” too 🙃


--Quick start--

Connect your display panel or programmable speaker to the circuit network.

In a display message / alert message, type:

[ ]

This inserts the default signal value (see “Default signal selection” below).

Example: 

"Speed: [prec 1][rate]km/s   Δ: [delta]"


--Default signal selection--

If you don’t explicitly pick a signal with a [sig ...] directive, the mod uses:

-Display panels: the first signal from the message’s circuit condition (i.e. condition.first_signal)

-Programmable speakers: the alert icon signal, otherwise the speaker’s circuit condition first signal

If nothing specifies a signal, the placeholder evaluates as 0 (by design).


--Placeholders--

These output a number (or derived number) using the currently selected signal:

[ ] — current value

[abs] — absolute value

[avg] — moving average

[delta] — change since last update (per tick interval)

[rate] — change per second

[min] / [max] — min/max observed over the rolling window


--Formatting mode overrides--

[exact] — force exact number formatting

[si] — force condensed SI formatting (k, M, G…)

Default formatting comes from the mod’s global setting (Exact vs SI).


--Signal selection (inline)--

You can select a specific signal for the following placeholders using:

[sig <type> <name> <quality>]

Examples:

"[sig virtual signal-A][ ]"

"[sig item iron-plate][ ]"

"[sig item iron-plate legendary][ ]"

"[sig fluid water][ ]"

Quality is optional. If omitted, normal quality is assumed.

To return to the message’s default signal:

"[sig]"


--Modifiers--

Modifiers stack and only affect the immediately following count placeholder.

[prec N] — set decimal places (e.g. [prec 2][avg])

[clamp A B] — clamp into range (e.g. [clamp 0 100][ ])

[floor] — round down

[ceil] — round up

[round] — round to nearest whole number

[sign] — adds a prefix sign (+ if positive, - if negative, ± if zero)

[pct] — appends % and applies [clamp 0 100]

Note: this is not a true percentage conversion (no scaling); it’s a convenience helper for 0–100 signals.


--Colouring counts--

-Automatic colouring (directive)

Use [color] or [colour] to colour the next placeholder automatically (green if positive, red if negative, yellow if ~zero (deadzone))

Example:

"[colour][sign][rate]/s"

[dz 0.01] Configurable colour deadzone (treats values with abs(value) < 0.01 as zero for the auto-colour decision to prevent colour flickering)

Example:

"[dz 0.01][colour][delta]"


-Manual rich text colouring

You can manually colour anything using Factorio rich text tags:

Example:

"[color=orange]Speed: [rate]kms/s[/color]"

This mod also supports UK spelling and will translate these on the fly:

Example:

"[colour=orange]Speed: [rate]km/s[/colour]"


--Examples--

Dashboard panel with icon and multiple values:
"[virtual-signal=signal-speed] v:[prec 1][ ] avg:[prec 1][avg] Δ:[sign][delta] rate:[colour][sign][prec 2][rate]/s"

Speaker alert:
"ALERT: power trending [colour][sign][rate]/s (now [ ])"

Clamp and percent:
"Accumulator: [pct][ ]"


--Compatibility--

Requires Factorio 2.0+

Space Age compatible, but not required


--Performance--

-Designed to be UPS-efficient

-Lightweight per-entity updates

-Template preservation (doesn’t permanently overwrite your messages)

-Grace window for editing so your manual changes don’t get instantly reverted


--Links--

GitHub (latest releases + source):
https://github.com/lyttelgeek/DisplaySignalCounts
