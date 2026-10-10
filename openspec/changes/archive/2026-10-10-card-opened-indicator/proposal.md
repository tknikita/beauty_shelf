# Proposal

## Why

Two follow-ups on the product card:

1. Opened products (`isOpened`) should be recognizable at a glance, so the
   period-after-opening date shown on the card is understandable without opening
   the item.

2. The earlier fix for counter-induced text truncation moved the `− N +` stepper
   into the metadata column on the date row. That made a quantity > 1 card taller
   than a quantity = 1 card and left the stepper inset from the right edge
   (not aligned with the overflow menu). Restore the compact, aligned card while
   keeping the text at full width.

## What Changes

- Add an **opened-package indicator** on the card when `Product.isOpened`: a
  small open-lock icon (with an "Вскрыта упаковка" tooltip) next to the status
  badge.
- Pin the quantity stepper to the card's **bottom-right corner** as a `Stack`
  overlay, aligned with the overflow menu. It no longer participates in the row
  layout, so the metadata text keeps full width (no truncation) and the card
  height is the same whether or not the stepper is shown.
- Keep the status badge `Flexible` with ellipsis so it can never overflow the
  row.

## Capabilities

### Modified Capabilities
- `product-expiry`: add a card requirement to mark opened packages.

## Impact

- `beauty_shelf_app/lib/widgets/product_card.dart` — opened indicator, stepper
  moved to a corner overlay
- `beauty_shelf_app/test/product_card_test.dart` — opened-indicator test; stepper
  test now asserts the text width is unchanged with the stepper
- `SPEC.md` — "Opened Product Tracking" bullet and changelog
- `openspec/specs/product-expiry/spec.md` — requirement added on archive
- No model, storage, API, dependency, or schema changes.
