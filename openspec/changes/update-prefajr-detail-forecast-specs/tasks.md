## 1. OpenSpec and Analysis

- [x] 1.1 Read attached Alarm Detailed View v6, Morning Hero v1.3, and Next 10 Mornings v4 specs.
- [x] 1.2 Inspect repository guidance, OpenSpec structure, existing docs, tests, and affected Swift files.
- [x] 1.3 Record proposal, design, requirements delta, risks, and implementation plan.

## 2. Shared Wake-Mode Semantics

- [x] 2.1 Change visible quick wake mode labels and accessibility copy to `Pre-Fajr | Fajr | Quiet`.
- [x] 2.2 Update date-specific Pre-Fajr selection to default to Tahajjud-only outside Ramadan and locked Fasting in Ramadan.
- [x] 2.3 Preserve explicit Pre-Fajr intention/fast-type/audio choices when switching through Quiet where the existing override model supports it.

## 3. Alarm Detailed View

- [x] 3.1 Update detail selector, purpose labels, fast-type labels, context copy, and accessibility text to v6 wording.
- [x] 3.2 Keep the context card opportunity-aware in Fajr, Pre-Fajr, and Quiet modes, including Monday/Thursday chips.
- [x] 3.3 Rename and restyle the reset action as prominent `Reset to Defaults`.
- [x] 3.4 Preserve the eligible non-Ramadan Pre-Fajr + Fasting Fajr adhan toggle and Ramadan lock behavior.

## 4. Next 10 Mornings

- [x] 4.1 Make the card collapsed by default with `NEXT 10 MORNINGS` header visible.
- [x] 4.2 Add a calm expansion affordance and keep row tap-to-detail behavior unchanged when expanded.
- [x] 4.3 Ensure expansion/collapse is UI-only and does not mutate wake state, scheduling, or overrides.

## 5. Verification

- [x] 5.1 Update focused presentation/resolution tests for Pre-Fajr labels, Tahajjud default, detail context copy, reset label, and forecast collapse.
- [x] 5.2 Run `openspec validate update-prefajr-detail-forecast-specs --strict`.
- [x] 5.3 Run targeted XCTest suites for changed presentation/resolver behavior.
- [x] 5.4 Run `git diff --check`.
