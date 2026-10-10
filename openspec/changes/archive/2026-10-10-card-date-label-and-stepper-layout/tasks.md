# Tasks

## 1. Remove the binding-limit label

- [x] 1.1 Simplify `_getDateText()` in `beauty_shelf_app/lib/widgets/product_card.dart` to return only `до DD.MM.YYYY` (drop the `switch (product.expiryBasis)` labels) — verified by the updated `test/product_card_test.dart` assertions

## 2. Fix the quantity-stepper layout

- [x] 2.1 Move the `_QuantityStepper` out of the right-hand controls column and into the metadata column's bottom row alongside the (now `Expanded`) expiry date, keeping the opaque tap-absorbing `GestureDetector` — verified by a widget test that the stepper is present and the card has no overflow
- [x] 2.2 Wrap the status badge in `Flexible` with `maxLines: 1` + ellipsis so a long status can never overflow the row — verified by `flutter analyze` and the widget tests

## 3. Tests and docs

- [x] 3.1 Rewrite the three `test/product_card_test.dart` cases to assert the date is shown and both labels (`после вскрытия`, `срок производителя`) are gone; add a regression test that the stepper does not squeeze the text — verified by `flutter test`
- [x] 3.2 Update `SPEC.md` ("Opened Product Tracking" bullet + changelog) and remove the "Product card indicates which limit is binding" requirement from the `product-expiry` spec — verified by re-reading

## 4. Verification

- [x] 4.1 Run `flutter analyze` and `flutter test` in `beauty_shelf_app/` and confirm both pass

## Notes

- The owner performs a manual emulator check before the release is re-cut; that
  step lives with the release, not with this change.

