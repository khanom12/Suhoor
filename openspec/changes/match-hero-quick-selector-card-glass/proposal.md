# Match Hero Quick Selector Card Glass

## Summary

Update only the Morning Hero quick wake-state selector shell so the Fast/Fajr/Quiet pill uses the same grouped translucent glass treatment as the Weekly Fajrcast and Next 10 Mornings cards.

## Motivation

The selector currently still reads visually heavier and more frosted than the grouped forecast cards below it. The user-visible control should keep its existing size, layout, labels, selection behavior, and animations while sharing the card stack's glass language.

## Scope

- Morning Hero quick selector outer pill styling.
- A small shared glass-surface option needed to preserve pill geometry while reusing the grouped card surface treatment.

## Out of Scope

- Wake-state resolution, scheduling, persistence, or downstream forecast logic.
- Quick selector labels, ordering, sizing, interaction behavior, or animations.
- Fajr adjuster row behavior.
