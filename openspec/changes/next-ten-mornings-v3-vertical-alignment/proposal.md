## Summary

Align the Next 10 Mornings card with the v3 forecast specification by tightening the row grid and implementing vertical centering across date, tag, and wake-time/status elements.

## Problem

The current card already has the v2/v2.1 tag behavior, but the row still uses baseline alignment for the outer row. The v3 spec explicitly requires row content to be vertically centered between dividers and forbids row-level `.firstTextBaseline` alignment for the date/tag/time trio.

The v3 spec also describes a measured middle tag lane between shared date and time lanes with minimum gaps. The current implementation instead balances the outer lanes to force the tag lane to the row center. That was a useful fix, but it now differs from the v3 spec language.

Finally, the forecast tags still use the app's broader compact chip padding. V3 asks for tighter forecast-specific chip metrics so normal two-tag pairs such as `[Fajr] [White Days]` remain visible on supported iPhone widths.

## Scope

- Next 10 Mornings row metrics
- Next 10 Mornings SwiftUI row layout
- Next 10 Mornings tag chip spacing/padding
- Focused presentation tests

## Non-Goals

- Do not change prayer-time calculation, fasting compatibility, alarm scheduling, persistence, or navigation.
- Do not change tag doctrine, tag colors, card shell, divider treatment, row copy, or accessibility semantics.
