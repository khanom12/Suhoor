## Summary

Defer active Month Planning entitlement enforcement in Debug/development builds so the full Gregorian and Hijri Month Planning flow can be tested end to end while preserving the production entitlement seam.

## Problem

Month Planning currently routes through the shared Free/Plus/Complete entitlement model. That is the correct architecture for production, but during active development the default Free snapshot blocks the Home tiles behind a locked preview. This prevents simulator and physical-device validation of the new Month Picker, Month Detail, Monthly Fajrcast placeholder, row navigation, and Day Detail integration.

## Scope

- Add a centralized development entitlement override in the entitlement provider.
- Make Month Planning consume the centralized effective entitlement state.
- Keep raw entitlement snapshots and pricing/tier concepts intact.
- Keep Release/production builds on the real entitlement path.
- Document that final Month Planning monetization enforcement is deferred to a later pricing/entitlement pass.
- Add focused test coverage for the Debug override and opt-out path.

## Non-Goals

- Do not delete the entitlement model or pricing tiers.
- Do not force Release/production users to Complete.
- Do not introduce purchase, subscription, receipt, or paywall logic.
- Do not change unrelated Home, Next 7/10, Day Detail, or alarm scheduling behavior.
- Do not reintroduce Tahajjud or non-fasting pre-Fajr behavior.

## User-Visible Impact

In Debug/development builds, Calendar Months and Hijri Months open their pickers without the locked preview blocking the flow. Month Detail and existing Day Detail navigation can be tested fully, including Suhoor/Fasting controls where the current resolver/domain model already supports them.

Release/production behavior remains structurally governed by the entitlement provider rather than being permanently unlocked.

## Persistence, Scheduling, and Migration Impact

This change does not migrate data, create durable day records from Month Planning browsing, or schedule platform alarms from month browsing. It only changes which entitlement snapshot Month Planning reads during active development.
