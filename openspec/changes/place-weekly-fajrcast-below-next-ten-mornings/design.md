## Decisions

1. **Reorder at the home composition boundary.**
   `SubhHomeView` already composes the resolved Tomorrow Morning, Weekly Fajrcast, and Next 10 Mornings surfaces. The change should only swap the existing view order so the data and card implementations remain untouched.

2. **Preserve existing behavior.**
   Weekly Fajrcast keeps its focused-day state, live hero wake preview, detail navigation, and selection callbacks. Next 10 Mornings keeps row navigation and snapshot input.

## Risks

- This is a low-risk presentation change. The main risk is accidental behavior churn, so implementation should avoid copy, styling, snapshot, resolver, and card-internal edits.
