# Design

## Context

See `proposal.md`. The card is a `Card` → `IntrinsicHeight` → `Row` of media /
expanded metadata / right-hand controls. The quantity stepper is ~80dp wide vs
~48dp for the overflow menu, so putting it in the controls column shrank the
metadata column and truncated the text. Putting it in the metadata column (the
previous attempt) fixed the width but changed the card height and left the
stepper inset from the right edge.

## Goals / Non-Goals

**Goals:**
- Mark opened products on the card.
- Keep the metadata text at full width whether or not the stepper is shown.
- Keep the stepper aligned with the overflow menu and the card height unchanged.

**Non-Goals:**
- Changing the stepper's sizing/behaviour or the status thresholds.
- Rewriting the expiry model or the form.

## Decisions

**1. Opened indicator = the official PAO symbol + tooltip in the badge row.**
The official period-after-opening vector symbol (`assets/icons/pao_symbol.svg`,
rendered with `flutter_svg`) sits right after the status badge and is wrapped in
a tooltip (`Вскрыта упаковка`). It is semantically the product's *state*, so it
belongs on the state (badge) row. Alternative — a generic `lock_open` icon — was
rejected as it does not read as a cosmetic container; alternative — an
image-corner badge — was rejected because it obscures the photo.

**2. Right-hand controls as a `Stack` overlay (menu + stepper grouped).**
The `Card` child becomes a `Stack`: the non-positioned child is the existing
`IntrinsicHeight(Row(...))`, whose right-hand slot is only a fixed `SizedBox`
reserving the menu's width (~56dp). The overflow menu and (when present) the
quantity stepper are painted in a `Positioned(top: 0, bottom: 0, right: 4)`
`Column` that is vertically centred and end-aligned, reproducing the original
menu-above-stepper grouping. Because the controls are an overlay, the metadata
column (`Expanded`) is exactly as wide as when no stepper is shown, and the card
height equals the quantity = 1 case.
Alternative — a fixed-width controls column sized to the stepper — was rejected
because it would permanently narrow the text even with no stepper; alternative —
putting the stepper in the metadata column — was rejected because it made the
card taller and left the stepper inset from the menu.

**3. Opened tap absorption preserved.**
The stepper is wrapped in an opaque `GestureDetector(onTap: () {})` so incidental
taps on the stepper don't trigger the card's swipe/tap handler (drag-to-swipe is
unchanged).

**4. Status badge stays `Flexible`.**
Defensive against a very long status string (`Просрочено · 1234 дн.`).

## Risks / Trade-offs

- [The stepper overlays the bottom-right; a very long date on an extremely narrow
  screen could pass under it] → The date is left-aligned and short
  (`до DD.MM.YYYY`); at the app's target widths there is no overlap. The date
  still ellipsizes rather than overflowing.
- [Icons are not the colour of the status badge] → Intentional: the opened
  indicator is deliberately neutral (not a severity signal).

## Migration Plan

Pure UI change; no data migration. Ship a new APK. Rollback is a revert.
