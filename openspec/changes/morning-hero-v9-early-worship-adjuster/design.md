# Design

## Data Flow
`MorningHomePresentation` remains the data/presentation boundary for the hero. It chooses one of two supported adjustment windows:

- default: Fajr begins to Fajr ends
- early-worship: final-third start to Fajr begins

The final-third start is derived before SwiftUI rendering from the resolved prayer window's previous Maghrib and target Fajr begin. SwiftUI receives already-resolved boundary dates/display strings and only maps positions to times for the active adjustment range.

## Eligibility
Use early-worship mode only when the resolved day has intended fasting, Ramadan/Qada/Kaffarah/Vow/voluntary intent, or intended Tahajjud, and the wake marker is inside final-third start through Fajr begins.

Ordinary `.suhoor` secondary context without fasting tags remains default within-Fajr behavior when the wake sits in Fajr begins through Fajr ends.

## Relation Copy
Default mode keeps existing copy:

- `Wake up {X} min before Fajr ends`
- `Wake up as Fajr begins`
- `Wake up as Fajr ends`

Early-worship mode uses:

- `Wake up {X} min before Fajr begins`
- `Wake up for the last third of the night`
- `Wake up as Fajr begins`

Urgent red is based only on rounded minutes before Fajr ends and now follows the v0.9 threshold of 14 minutes or less.

## Rendering
`FajrWindowRangeTrack` uses marker style from the display mode:

- default: left circle, right circle
- early-worship: left vertical tick, right circle

The track and marker gesture remain shared so drag behavior stays consistent.

## Persistence
`ScheduleManager.commitHeroWakeAdjustment` selects the same supported window as the hero. Early-worship commits are clamped to final-third start through Fajr begins; default commits remain clamped to Fajr begins through Fajr ends. The saved override remains date-specific fixed wake time.
