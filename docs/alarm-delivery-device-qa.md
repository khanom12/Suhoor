# Alarm Delivery Device QA

This checklist covers behavior that simulator tests cannot prove with enough confidence. Record device, iOS version, build, date, timezone, and tester initials when running it.

## AlarmKit

- AlarmKit unavailable device: verify Subh uses notification fallback and does not claim AlarmKit delivery.
- AlarmKit not determined: request authorization and verify schedule refresh/reconciliation runs afterward.
- AlarmKit denied: verify active wake intent remains active and delivery status is blocked/degraded, not Quiet.
- AlarmKit authorized: schedule tomorrow wake and verify the wake alarm appears/fires at the expected local time.
- AlarmKit revoked after scheduling: foreground app and verify delivery status updates without changing wake mode or day purpose.

## Notifications

- Notifications authorized: verify fallback notifications schedule for wake/reminder/boundary events where policy selects notifications.
- Notifications denied: verify no notification is silently scheduled and compact warning copy appears.
- Notification pending state manually cleared or changed: foreground app and verify reconciliation reports missing or mismatched delivery.

## Device State

- Silent switch / Focus / Do Not Disturb: verify user-facing reliability language remains honest and does not guarantee wake delivery.
- Device reboot or app kill: relaunch and verify schedule refresh/reconciliation runs.
- Timezone change: verify old date-scoped identifiers are repaired and tomorrow's local wake date remains correct.
- Significant time change: verify schedule refresh/reconciliation runs and stale past events are not treated as missing future deliveries.

## Morning Modes

- Fajr: verify active wake is scheduled through the selected channel.
- Suhoor: verify before-Fajr wake remains active when the later Fajr-begins adhan cue is disabled.
- Quiet: verify delivery is suppressed or cancelled while underlying Fajr/Suhoor context remains restorable.
- Fajr adhan wake audio: verify adhan sound selection does not show the alarm as off.

## User-Observed Reliability Regressions

- Wrong-time firing: schedule a Suhoor or Fajr wake, leave the device idle, and verify the alarm fires only at the expected local wake time, not at unrelated daytime times.
- Missed wake: schedule the next morning wake, leave the app terminated overnight, and verify the expected alarm fires or the app records/reports a delivery failure without rewriting the morning as Quiet.
