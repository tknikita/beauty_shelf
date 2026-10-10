# Proposal

## Why

Two problems on the product card:

1. Opened products append a binding-limit suffix to the expiry date
   (`· после вскрытия` / `· срок производителя`). It clutters the line and is
   more noise than signal for the user, who only needs the effective date.
2. When a product has `quantity > 1`, the `− N +` stepper is rendered inside the
   right-hand controls column. That widens the column, shrinking the metadata
   column (`Expanded`) and truncating the text lines beside it — the name,
   subtitle and, on narrow screens, even the status badge (a `RenderFlex`
   overflow that paints the yellow/black stripes).

## What Changes

- Remove the binding-limit label from the card's date line. The card always shows
  just `до DD.MM.YYYY` (the effective expiry), for opened and unopened products
  alike. `Product.expiryBasis` stays on the model but is no longer rendered.
- Fix the card layout so the quantity stepper never steals width from the text:
  the stepper moves into the metadata column and shares the bottom row with the
  expiry date, so the text keeps the same width whether or not the stepper is
  present. The status badge is made flexible (ellipsis) as a safety net so it can
  never overflow.
- Update the widget tests that asserted the removed labels and add a regression
  test that the card lays out without overflow when the stepper is shown.

## Capabilities

### Modified Capabilities
- `product-expiry`: drop the "Product card indicates which limit is binding"
  requirement; the card no longer exposes which limit produced the date.

## Impact

- `beauty_shelf_app/lib/widgets/product_card.dart` — date text, stepper placement,
  flexible status badge
- `beauty_shelf_app/test/product_card_test.dart` — flip label assertions, add
  stepper-layout regression test
- `SPEC.md` — "Opened Product Tracking" bullet and changelog no longer claim the
  card labels the binding limit
- `openspec/specs/product-expiry/spec.md` — requirement removed on archive
- No model, storage, API, dependency, or schema changes.
