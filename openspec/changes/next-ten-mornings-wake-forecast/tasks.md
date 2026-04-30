## 1. OpenSpec

- [x] 1.1 Create proposal, design, and delta spec for the Next 10 Mornings home card.
- [x] 1.2 Validate the OpenSpec change in strict mode.

## 2. Presentation Pipeline

- [x] 2.1 Add a dedicated `NextTenMorningsPresentation` display model and tag resolver that consume resolved row state rather than parsing row strings.
- [x] 2.2 Apply the tag doctrine: Fajr fallback, Ramadan/quiet-mode replacement, intended fasting tags, Tahajjud, opportunity tags, Monday/Thursday suppression, Shawwal 6 completion-aware suppression, and three-tag cap.
- [x] 2.3 Preserve Gregorian-first date labels and accessibility labels with full hidden meaning.

## 3. SwiftUI Card

- [x] 3.1 Replace the legacy visible Morningcast header with `NEXT 10 MORNINGS`.
- [x] 3.2 Render rows as date label, tag cluster, and trailing wake time/status only.
- [x] 3.3 Reuse the app glass shell, subtle dividers, row tap-to-detail navigation, and existing tag visual language.

## 4. Validation

- [x] 4.1 Add focused tests for header copy, row content, tag priority/suppression, Shawwal 6 suppression, capping, date labels, and accessibility.
- [x] 4.2 Run OpenSpec strict validation.
- [x] 4.3 Run focused Swift tests and a build check where practical.
- [x] 4.4 Commit and push the completed change to `main`.
