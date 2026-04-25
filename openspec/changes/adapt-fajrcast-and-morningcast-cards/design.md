## Context

`WeeklyFajrcastCard` and wake-list entries already communicate useful schedule information. The redesign should keep those assets while reframing them as dashboard cards on the Subh home.

## Goals / Non-Goals

**Goals:**
- Reuse existing visuals where possible.
- Rename the upcoming wake list to Morningcast in the primary home.
- Keep trust/reliability copy visible when provider state is degraded.

**Non-Goals:**
- No new chart engine.
- No change to underlying timezone/date calculations.

## Decisions

- Keep `WeeklyFajrcastCard` as the first-wave weekly card.
- Build Morningcast rows from existing wake-list entries.
- Prefer copy changes and adapter models over duplicating card logic.

## Risks / Trade-offs

- [Risk] Some reused detail views may still use Wake/Alarm labels. → Mitigation: adjust primary home labels now and leave deeper detail text for follow-up if outside the MVP surface.
