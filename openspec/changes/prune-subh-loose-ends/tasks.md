## 1. Inventory

- [x] 1.1 Map compiled Swift files and identify production entry points.
- [x] 1.2 Classify MVP-critical files versus retired legacy surfaces.

## 2. OpenSpec

- [x] 2.1 Create proposal, design, spec deltas, and tasks for `prune-subh-loose-ends`.
- [x] 2.2 Validate the new OpenSpec change in strict mode.

## 3. Production Code Prune

- [x] 3.1 Delete retired tab-era UI surfaces and old alarm customization wrappers with no MVP entry point.
- [x] 3.2 Remove ScheduleManager APIs/providers used only by deleted surfaces.
- [x] 3.3 Reduce legacy navigation intents to live MVP intents.
- [x] 3.4 Preserve Fajrcast, Morningcast, Tomorrow Morning detail, settings, permissions/reliability, prayer/Hijri config, and scheduling behavior.
- [x] 3.5 Remove disabled countdown/test-alarm diagnostic infrastructure from the MVP launch path.

## 4. Test And Artifact Prune

- [x] 4.1 Remove orphan tests for deleted legacy surfaces.
- [x] 4.2 Keep or update focused tests that protect MVP wake resolution, home cards, Fajrcast, settings, and scheduling.
- [x] 4.3 Remove stale scheme-external tests that referenced deleted diagnostic types.

## 5. Verification

- [x] 5.1 Run `openspec validate prune-subh-loose-ends --strict`.
- [x] 5.2 Run `openspec validate --all --strict`.
- [x] 5.3 Run `xcodebuild -list -project Subh.xcodeproj`.
- [x] 5.4 Run focused tests for MVP wake/home/Fajrcast/settings behavior.
- [x] 5.5 Run the full suite or document only the known baseline failure.
- [x] 5.6 Commit and push the validated cleanup to `main`.
