# Subh Specs — May 30 Reconciled Package

Use the root-level markdown files as the active implementation-facing specs.

Original uploaded specs are preserved under:

```text
Archive/originals-before-may30-reconciliation/
```

The detailed update report is:

```text
SUBH_SPEC_RECONCILIATION_REPORT_MAY30.md
```

Primary source-of-truth files:

1. `00-subh-spec-index-v3.md`
2. `subh-quiet-pause-hero-wake-flow-alignment-spec-v1.md`
3. `subh-morning-resolution-contract-state-ownership-spec-v3.md`
4. `subh-quick-wake-mode-intent-mutation-contract-v2.md`
5. `subh-morning-hero-item-spec-v15.md`
6. `subh-alarm-detail-view-screen-spec-v7.md`
7. `subh-quiet-mode-quiet-morning-contract-spec-v1.md`
8. `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`

## Suhoor-to-Fajr correction

A Suhoor wake acknowledgement does not automatically satisfy the Fajr wake check. After Fajr begins, Home/Detail may show `I’m awake for Fajr` before `I prayed Fajr`.
