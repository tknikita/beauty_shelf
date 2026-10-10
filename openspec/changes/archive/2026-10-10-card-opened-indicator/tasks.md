# Tasks

## 1. Opened-package indicator

- [x] 1.1 Render `Icons.lock_open` (with a `Вскрыта упаковка` tooltip) next to the status badge when `Product.isOpened` — verified by a widget test asserting the icon is present for an opened product and absent otherwise

## 2. Compact stepper in the corner

- [x] 2.1 Move the `_QuantityStepper` out of the controls column and pin it with `Positioned(right: 4, bottom: 10)` inside a `Stack`, so it does not affect the row layout — verified by a widget test that the metadata text width is identical with and without the stepper, and no overflow occurs

## 3. Tests and docs

- [x] 3.1 Update `test/product_card_test.dart` (opened-indicator case; stepper width-parity assertion) — verified by `flutter test`
- [x] 3.2 Update `SPEC.md` and the `product-expiry` spec delta — verified by re-reading

## 4. Verification

- [x] 4.1 Run `flutter analyze` and `flutter test` in `beauty_shelf_app/` and confirm both pass
- [x] 4.2 Visual check via a rendered card (golden) in the opened + quantity > 1 state
