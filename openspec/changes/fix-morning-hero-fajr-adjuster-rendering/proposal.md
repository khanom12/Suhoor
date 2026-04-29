# Fix Morning Hero Fajr Adjuster Rendering

## Summary

The v0.3 Morning Hero Fajr range adjuster can disappear on ordinary early wake mornings because the presentation layer treats `.suhoor` as a fasting-day hide condition. In the resolver, `.suhoor` may be attached as a secondary context whenever the wake is early, even when the target morning is not a fasting day.

This change restores the Fajr begin/end visual and drag affordance for ordinary within-Fajr wake plans, while keeping the v0.3 fasting, missing-data, and out-of-window hiding rules intact.

## Motivation

The hero is the user's immediate answer to "what does the next morning look like?" If the Fajr row is absent on the normal active wake path, the user loses the Fajr begin/end context, the wake-position marker, and the immediate adjustment control.

## Non-Goals

- Do not introduce the deferred fasting-day alternative visual.
- Do not change prayer-time calculation behavior.
- Do not change the date-specific override persistence model from the v0.3 wake adjuster.
- Do not redesign the broader hero layout beyond making the existing v0.3 row render and verify correctly.

