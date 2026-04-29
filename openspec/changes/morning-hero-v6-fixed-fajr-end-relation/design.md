## Context

The v0.5 hero relation formatter allowed the final line to vary by anchor: before Fajr begins, after Fajr begins, before Fajr ends, and exact start/end boundary phrases. The v0.6 spec intentionally removes that variation for the final visible line.

## Decisions

1. **Use Fajr end as the display boundary for active relation copy.**
   Active relation text derives from `prayerWindow.fajrEnd` and `schedule.wakeDate`, rather than from the resolved wake anchor label.

2. **Keep missing-Fajr state explicit.**
   If Fajr end is unavailable, the hero continues to show the existing missing-Fajr fallback instead of inventing a relation.

3. **Keep inactive copy stateful.**
   Off/no-alarm copy remains state copy. Skipped planned-wake copy may use the same compact Fajr-end offset when Fajr end and the planned wake time are available.

4. **Use one helper for active and drag relation copy.**
   The initial display and tentative drag display should not diverge. Both calculate whole minutes from wake time to Fajr end and format `Wake up {X} min before Fajr ends`.

## Risks / Trade-offs

- Wake times after Fajr end can produce a negative minute value if such a state reaches the active relation formatter. That follows the spec's fixed `{X}` pattern and keeps calculation transparent, while the within-Fajr visual remains hidden for out-of-window timings.
