# Design

## Context

See `proposal.md`. The card (`beauty_shelf_app/lib/widgets/product_card.dart`)
is a `Row` of: fixed-width media (76), an `Expanded` metadata column, and a
right-hand controls column that held the overflow menu **and** the quantity
stepper. The stepper is much wider (~80px) than the menu icon (~48px), so
showing it grew the right column, shrank the `Expanded` metadata column, and
truncated the text plus overflowed the status badge.

## Goals / Non-Goals

**Goals:**
- Show only the effective expiry date on the card (no binding-limit label).
- Keep the metadata text width constant whether or not the stepper is shown.
- Never overflow the card row, on any realistic phone width.

**Non-Goals:**
- Removing `Product.expiryBasis` (still a valid model signal, still unit-tested).
- Changing the status thresholds, colours, or the stepper's behaviour/step size.
- Changing how quantity is edited in the form.

## Decisions

**1. Drop the label in `_getDateText()` and return only the formatted date.**
The `switch (product.expiryBasis)` is removed; the method becomes a one-liner.
Alternative — keep the label behind a setting — was rejected as out of scope: the
user wants it gone.

**2. Move the stepper out of the controls column into the metadata column.**
The stepper now lives in the same `Row` as the expiry date: an `Expanded` date
text plus the stepper aligned to the end. Because the stepper is inside the
`Expanded` metadata column, it consumes that column's own width (which is
plenty) instead of adding a new column to the row, so the name/subtitle/badge
keep their full width. Alternative — a fixed-width controls column sized to the
stepper — was rejected because it would permanently narrow the text even when no
stepper is shown.

**3. Absorb taps on the stepper with an opaque `GestureDetector`.**
Preserved from the previous implementation so tapping the stepper does not fall
through to the card's swipe/tap handler. Drag-to-swipe is unchanged.

**4. Wrap the status badge in `Flexible` with `maxLines: 1` + ellipsis.**
Defensive: a very long status string (`Просрочено · 1234 дн.`) can no longer
overflow the row even on a 320dp device.

## Risks / Trade-offs

- [The stepper now sits on the date line, so a quantity>1 card is ~13px taller
  than before] → Acceptable; the date line already existed and the previous
  layout was the same height only because the controls column happened to be
  shorter than the metadata column.
- [Very long product names still ellipsize (by design, `maxLines: 1`)] → This
  predates the change and is unaffected; the fix removes the *extra* truncation
  caused by the stepper.

## Migration Plan

Pure UI change; no data migration. Ship a new APK. Rollback is a revert.
