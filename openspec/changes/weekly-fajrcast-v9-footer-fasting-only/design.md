## Design Notes

### Footer Semantics

The v9 compact footer has a sharper information hierarchy:

1. The primary line always explains the focused day's Fajr begin/end boundaries when data is available.
2. The secondary line is reserved for one contextual fact: the focused day is an explicit fasting day outside Ramadan.

Alarm timing and off-state remain visible through the chart marker, selected-day callout, and accessibility summary. Adjusted, Tahajjud, Ramadan, and broader context remain modeled for detail surfaces and accessibility/detail payloads, but they no longer create a visible compact footer prefix such as `Adjusted:` or `Ramadan:`.

### Fasting Detection

The data provider should only emit compact secondary footer text when the focused point is marked as fasting context and is not tagged as Ramadan. This keeps Ramadan from producing repetitive daily footer lines while preserving the explicit non-Ramadan fasting signal.

The renderer continues to consume precomposed `summary.secondaryText`. It should not infer Ramadan or fasting from visual state.

### Temporal Wording

The fasting secondary line follows the focused day's temporal subject:

- `Today is a fasting day.`
- `Tomorrow is a fasting day.`
- `Friday is a fasting day.`
- `Yesterday was a fasting day.`

The existing focused-day subject helper and Fajr-window state can provide this tense without adding a new date-resolution path.

### Footer Bottom Breathing

Footer top padding remains unchanged. Bottom padding becomes a distinct value so the final visible footer line has intentional space beneath it:

- smaller standard stops: at least 8 pt
- default stop: about 10 pt
- larger standard stops: at least 12 pt
- accessibility stops: `max(12, 0.55 * scaledFooterLineHeight)`

No blank second line is reserved when secondary text is absent; the bottom breathing applies directly below the primary line.
