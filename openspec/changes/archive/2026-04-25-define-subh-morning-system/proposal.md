## Why

The current product framing inherits the wrong mental model: a tabbed alarm and fasting utility makes the user assemble tomorrow morning manually from separate surfaces. Subh needs a doctrine-level contract that treats Fajr as the primary anchor, tomorrow morning as the core object, and fasting or observance states as contextual overlays on one morning engine.

## What Changes

- Define Subh as a Fajr-centered morning system for Muslims rather than a Suhoor-first alarm or fasting planner.
- Establish "tomorrow morning" as the primary resolved unit for product, domain, and presentation decisions.
- Define one morning-resolution engine with layered contexts for fasting, Ramadan, special observances, travel, masjid alignment, reliability state, and overrides.
- Define the first-wave home information architecture as one dashboard-style morning surface rather than bottom-tab product areas.
- Define the MVP wake behavior as 30 minutes before the supported Fajr end boundary, with visible trust language where the boundary is provider-derived or approximate.
- Define rename compatibility: user-facing product language moves to Subh while the first implementation wave preserves the existing bundle identifier and legacy Suhoor storage namespaces.
- **BREAKING**: The primary app experience no longer treats Wake, Plans, and Progress as top-level tabs.

## Capabilities

### New Capabilities
- `subh-product-doctrine`: Product and architecture doctrine for anchor-first Subh behavior, tomorrow-morning modeling, and layered contexts.
- `morning-resolution`: Resolution contract for deriving tomorrow morning from Fajr boundaries, settings, location, calculation method, context flags, reliability state, and overrides.
- `single-screen-morning-home`: Single-screen home contract for the Subh dashboard and its first-wave cards.
- `fajr-end-mvp-wake`: MVP wake behavior that anchors the main wake to 30 minutes before the supported Fajr end boundary.
- `subh-rename-compatibility`: Rename and compatibility contract for moving visible identity to Subh while preserving first-wave local data identity.

### Modified Capabilities
- None.

## Impact

- Affects product doctrine, OpenSpec project context, app identity, Xcode project/scheme/test target naming, visible copy, root navigation, wake defaults, migration behavior, and home presentation models.
- Existing scheduled alarms and cached schedules may need regeneration after the default wake anchor changes; user-customized persisted wake settings must remain unchanged.
- The app bundle identifier remains `khanomar.Suhoor` and legacy `Suhoor.*`/existing storage keys remain valid during this wave.
- No new third-party dependencies are introduced.
