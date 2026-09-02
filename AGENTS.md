# AGENTS.md

## Purpose
This repository is a greenfield build of **Subh**, a Fajr-centered morning system for Muslims.

Treat the repo as first-principles product work. Do **not** preserve, reference, or optimize for legacy product names, information architecture, copy, feature boundaries, or code patterns unless a task explicitly requires migration work.

This file defines the default working doctrine for Codex in this repository. Keep decisions aligned with it.

## Product truth
- The product is a **Fajr-centered morning system**, not a generic alarm clock.
- The product's primary unit is **tomorrow morning**, not an alarm row.
- The user's morning is organized around a meaningful pre-existing anchor; the system should resolve, explain, and execute around that anchor.
- Supporting contexts such as fasting, special observance, travel, work constraints, reminders, and exceptions modify the same morning engine. They do **not** become separate products or parallel wake engines.
- The product should help the user understand what tomorrow requires, wake reliably, do what matters first, and move on with minimal friction.

## Core jobs to be done
1. Explain what tomorrow morning looks like.
2. Resolve the right wake plan for that morning.
3. Execute that wake plan reliably.
4. Reduce repetitive setup and mental calculation.
5. Preserve trust through clarity, privacy, and predictable behavior.
6. Support reflection and improvement without shame, noise, or distraction.

## Non-goals
- Do not turn the product into a generic Islamic superapp.
- Do not optimize for maximal engagement, feeds, streak addiction, or ad inventory.
- Do not add features only because competitors have them.
- Do not create separate conceptual products for niche morning cases.
- Do not present the app as a source of religious authority.
- Do not use guilt-heavy, manipulative, or juvenile mechanics.
- Do not add AI features unless they clearly reduce friction or improve morning clarity.

## Greenfield rules
- Assume no legacy constraints unless explicitly stated in the task.
- Prefer simple, durable abstractions over backwards-compatible ones.
- Remove accidental legacy language from code, docs, tickets, and copy when encountered.
- Use names that reflect the current product model, not historical artifacts.
- When architecture is undecided, propose options briefly and default to the simplest production-credible approach.
- Avoid building placeholder complexity for hypothetical future migrations.

## User model
- Default user: a practicing Muslim who wants mornings organized around Fajr.
- Secondary cases include shift workers, travelers, students, parents, new Muslims, and users with varying observance levels.
- Design for low-consciousness states: tired, rushed, partially awake, low light, one hand, limited patience.
- The system should answer **"What does tomorrow morning look like?"** before asking the user to configure details.
- The product should be useful for committed users without becoming hostile to inconsistent users.

## Product principles
- **Anchor-first, not time-entry-first.**
- **One morning engine, many contexts.**
- **Explain before asking.**
- **Automate what is deterministic.**
- **Match wake friction to the stakes of the morning.**
- **Optimize for minimal screen time and strong execution.**
- **Make privacy, trust, and clarity first-class features.**
- **Build for year-round use, not a single season.**
- **Respect user dignity; encourage without shaming.**
- **Prefer fewer screens with clearer jobs.**

## Competition heuristics
Use competition to sharpen category clarity, not to drive feature copying.

- Generic clock apps own arbitrary time entry.
- Wake-enforcement apps own alarm-friction tactics.
- Sleep apps own sleep-timing optimization.
- Broad Muslim apps own breadth.
- This product should own the **Muslim morning itself**.

When evaluating a competitive idea, ask whether it strengthens our ownership of the morning-resolution system. If it does not, it is likely a distraction.

## Brand and positioning rules
- Describe the product as a **Fajr-centered morning system for Muslims**.
- Do not frame it as only an alarm, only a prayer-time utility, or a broad everything-app.
- Lead with clarity, reliability, alignment, and calm execution.
- Keep promises credible. Do not claim certainty, perfection, or guaranteed outcomes.
- Messaging should make the product feel serious, trustworthy, and deeply fit for purpose.

## Domain model expectations
Model the system around the next morning.

Preferred conceptual entities:
- `MorningPlan`: resolved state for a specific date and location
- `AnchorWindow`: relevant start/end boundaries and buffers
- `WakePlan`: alarm sequence, escalation, verification, and fallbacks
- `ContextFlags`: fasting, travel, override, special observance, work constraint, etc.
- `ExecutionResult`: dismissal, completion, misses, retries, notes, and reliability events

Modeling rules:
- Distinguish **inputs**, **derived outputs**, **user overrides**, and **observed outcomes**.
- Avoid overloaded booleans when an explicit enum or state object is clearer.
- Keep business rules explicit and auditable.
- Keep domain logic pure and testable.
- UI, device APIs, scheduling, storage, analytics, and network calls must sit outside the core resolution engine.

## Architecture rules
- Separate pure domain logic from platform adapters.
- No prayer-time or morning-resolution logic inside UI components.
- No UI-driven business rules that cannot be tested independently.
- Wrap external services and libraries behind interfaces.
- Centralize configuration, constants, and calculation assumptions.
- Use typed models and explicit state transitions.
- Favor deterministic, auditable behavior over hidden heuristics.
- Experimental logic must be gated, measurable, and easy to remove.
- Keep copy and presentation separate from calculation logic.
- Design for offline-first or degraded-network operation whenever practical.
- Prefer modular architecture that can support iOS, Android, and shared business logic without duplicating the morning engine.

## Data and state modeling rules
- Model source-of-truth data explicitly.
- Separate canonical user settings from temporary overrides.
- Separate calculated schedule data from user-entered preferences.
- Store enough state to explain **why** a morning resolved the way it did.
- Preserve a clean precedence order when multiple contexts apply.
- Avoid schema shortcuts that make future explanation, debugging, or auditing harder.

## Religious and time-calculation rules
- Treat prayer and morning-time calculations as sensitive domain logic.
- Never invent religious claims, rulings, or certainty.
- Be explicit about what is calculated, configured, user-selected, or approximate.
- Support multiple calculation methods and visible settings.
- Preserve timezone, daylight-saving, and location correctness.
- Document assumptions whenever changing time-calculation behavior.
- When unsure about a religious claim, present it as configurable or document the source requirement rather than hard-coding one interpretation.
- Do not hide calculation choices behind opaque language.

## Alarm and reliability rules
- Alarm reliability is a core feature, not a polish layer.
- Never imply guaranteed wake reliability when OS permissions or platform limits weaken delivery.
- Surface degraded states clearly: permission missing, battery optimization, exact-alarm restrictions, background limits, muted channels, focus modes, or similar platform constraints.
- Design alarm flows with sensible fallbacks: prealarm, main alarm, escalation, verification step, backup path, and failure visibility.
- Prefer reliability and transparency over cleverness.
- Treat scheduling, rescheduling, and missed-window handling as first-class behavior.

Critical reliability scenarios to test:
- timezone changes
- daylight-saving transitions
- location changes
- app kill / background state
- device reboot
- missed scheduling windows
- Do Not Disturb / silent / vibrate states
- permission loss or revocation
- stale schedule regeneration
- override precedence conflicts

## UX and design rules
- Calm, focused, dignified, low-clutter UI.
- One screen should have one primary job.
- Show what changed and why.
- Respect low-light and half-awake use.
- Avoid dark patterns, attention traps, and ornamental complexity.
- Prioritize legibility, speed, and confidence over novelty.
- Build for accessibility from the start: readable text, strong contrast, motion restraint, haptics/audio options, screen-reader support, and large tap targets.
- Design for localization and RTL from the start.
- Do not assume English-only, North America-only, or city-specific defaults.

## Copy and tone rules
- Clear, calm, respectful, and operational.
- Do not be preachy, sentimental, overly cute, or aggressively market-y in product copy.
- Do not shame the user for missed mornings.
- Prefer plain language over jargon.
- Use Arabic or Islamic terms only when they improve precision; explain them when needed.
- Product copy should help the user act, not merely admire the interface.
- Empty states, errors, and degraded states must be especially clear and humane.

## Privacy and data rules
- Treat location, schedule, observance state, and alarm history as sensitive.
- Prefer local-first storage and on-device computation when feasible.
- Minimize collection. Do not add analytics or third-party SDKs without a clear product reason.
- No advertising assumptions.
- Any telemetry must answer a concrete product question and avoid collecting more than necessary.
- Privacy-sensitive changes require explicit documentation in the diff or PR summary.
- Never add hidden data flows.

## Metrics and experiment rules
Optimize for:
- reliable wake execution
- reduced manual setup
- morning-plan clarity
- trust
- retention across ordinary weeks, not only seasonal peaks
- fewer missed or broken alarm states

Do not optimize for:
- raw session length
- notification volume
- vanity engagement
- feature count

When proposing experiments, define:
- the user problem
- the behavioral hypothesis
- the success metric
- the failure metric or rollback condition

## Repository and tooling expectations
If the repository is being scaffolded or restructured:
- keep root commands predictable and CI-friendly
- prefer stable script names such as `dev`, `build`, `lint`, `typecheck`, `test`, and `e2e` when the stack supports them
- keep commands runnable from the repository root
- use one package manager consistently; do not mix lockfiles
- do not add production dependencies without a short justification
- prefer reusable scripts or skills over one-off manual command sequences

## Suggested repo shape for a true greenfield start
If the repo is empty and no stack has been mandated, prefer a structure that separates domain logic from device and presentation code. One acceptable starting shape is:

- `apps/mobile/`
- `packages/domain/`
- `packages/platform/`
- `packages/ui/`
- `packages/shared/`
- `docs/`
- `tests/` or `e2e/`

Adapt the exact layout to the chosen stack, but preserve the separation of domain, platform, and presentation.

## Working style for Codex
- Read this file before planning or editing.
- For complex or high-impact tasks, plan first.
- Restate the relevant constraints before implementation.
- Make small, reviewable changes.
- Do not mix unrelated refactors with feature work unless they are required.
- When requirements are underspecified, resolve using the product truth above. Ask only when the choice is irreversible, high-risk, or impossible to infer.
- Keep intermediate progress updates short and useful.
- Explain tradeoffs, especially around reliability, privacy, and architecture.
- Prefer directness over ceremony.

## Implementation expectations
Before changing code:
- inspect relevant files and existing patterns
- identify the domain boundary affected
- prefer the narrowest change that preserves long-term clarity
- note any assumptions that could affect reliability, correctness, or product positioning

After changing code:
- run the narrowest meaningful validation first, then broader checks as needed
- add or update tests for behavior changes
- run lint, type checks, and relevant test suites
- verify user-visible copy and edge states
- summarize what changed, why, how it was verified, and any remaining risk

## Testing expectations
Test behavior, not just implementation details.

Priority order:
1. domain-unit tests for morning resolution logic
2. integration tests for scheduling and persistence
3. UI tests for critical user flows
4. end-to-end tests for alarm and onboarding reliability where feasible

At minimum, protect:
- resolution precedence
- calculation changes
- override handling
- degraded-state behavior
- permission and reliability messaging
- any bug that previously escaped into production

## Definition of done
Work is not done until:
- behavior matches the request
- code follows the product model in this file
- relevant tests exist and pass, or the absence of tests is explicitly noted
- lint and type checks pass where available
- docs, config, and examples are updated when behavior or workflow changes
- no known reliability regression is left unexplained
- the diff is reviewable and free of unrelated noise

## Documentation rules
- Record durable decisions in `docs/`.
- Keep architecture decision records short and explicit.
- Update onboarding and setup docs whenever commands or structure change.
- Do not let README, docs, and implementation drift apart.
- When a mistake repeats twice, propose an `AGENTS.md` or docs update.
- Prefer documenting business rules once, clearly, near the domain they govern.

## Skills and local instructions
- Keep this root `AGENTS.md` high-signal.
- Put repetitive, specialized workflows in `.agents/skills/`.
- Prefer skills for narrow tasks such as time-calculation QA, mobile release checks, analytics review, content audits, or design-system sweeps.
- Add subdirectory `AGENTS.md` files only when a folder has genuinely local rules.
- Do not bloat the root file with narrow process detail that belongs in a skill or local instruction file.
- For substantive Fajr Now website, landing-page, positioning, marketing-copy, or marketing-design work, use `.codex/skills/fajr-landing-page/SKILL.md` as the orchestration workflow. It coordinates the project-scoped `product-marketing`, `customer-research`, `copywriting`, `copy-editing`, `cro`, `marketing-psychology`, and `frontend-design` skills in that order.
- Claude sessions should enter the same workflow through `.claude/skills/fajr-landing-page/SKILL.md`; the Codex files remain the canonical specialist definitions.

## PR and review expectations
PR summaries should usually include:
- what changed
- why it changed
- how it was validated
- user-visible impact
- open risks or follow-ups

During review, actively look for:
- product-model drift
- hidden reliability regressions
- privacy regressions
- unclear copy
- accidental complexity
- untested edge cases

## Decision filter
When choosing between options, prefer the one that is:
1. truer to the product model
2. simpler to explain
3. more reliable in real morning conditions
4. easier to test and audit
5. more respectful of the user's time, privacy, and attention

## Explicit red flags
Push back on changes that:
- shift the product toward a generic alarm clock
- create parallel morning engines
- increase engagement while weakening execution
- hide calculation assumptions
- weaken privacy without clear benefit
- add broad content or social surfaces unrelated to the morning system
- introduce copy or features that feel guilt-driven, noisy, or juvenile
- make the system harder to explain, trust, or verify
