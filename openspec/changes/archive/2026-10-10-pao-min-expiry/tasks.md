# Tasks

## 1. Effective-expiry model rule

- [x] 1.1 Change `Product.effectiveExpiryDate` (`beauty_shelf_app/lib/models/product.dart`) to return the earlier of the printed expiry and `opened_date + PAO` for opened products with an open date, keeping the printed-date fallbacks — verified by updating the two existing `product_test.dart` expectations and running `flutter test test/product_test.dart`
- [x] 1.2 Add an `ExpiryBasis` enum and a derived `expiryBasis` getter on `Product` (printed expiry / period-after-opening / none) computed from the same inputs — verified by unit tests covering printed-binding, PAO-binding, opened-without-date, and not-opened cases

## 2. Query and backend consistency

- [x] 2.1 Update the `getExpiringProducts` SQL in `beauty_shelf_app/lib/services/storage_io.dart` to `MIN(expiry_date, date(opened_date, '+' || expiry_days_after_open || ' days'))` when opened, otherwise `expiry_date` — verified by a test that an opened product inside the window via either limit is returned
- [x] 2.2 Update the expiring query in `backend/main.py` to the same `MIN(...)` logic and docstring — verified by running the backend pytest suite

## 3. Product card binding-limit indicator

- [x] 3.1 Render a short label in `beauty_shelf_app/lib/widgets/product_card.dart` from `expiryBasis` — verified by a widget test asserting the label for the PAO-binding and printed-binding cases and its absence when the product is not opened

## 4. Documentation

- [x] 4.1 Update the "Opened Product Tracking" section of `SPEC.md` to state that the effective expiry is the earlier of the printed expiry and `opened_date + PAO`, and that PAO cannot extend past the printed date — verified by re-reading the section
- [x] 4.2 Add a dated changelog entry in `SPEC.md` describing the corrected precedence — verified by re-reading the changelog

## 5. Implementation verification

- [x] 5.1 Run `flutter analyze` and `flutter test` in `beauty_shelf_app/` and confirm both pass
- [x] 5.2 Search the codebase for remaining usages that assume "PAO always wins" (e.g. old comments) and confirm none contradict the new rule

## Notes

- Additional file touched beyond the task list: `tests/test_api.py` — its `test_opened_uses_pao_not_printed_expiry` encoded the old PAO-wins backend behaviour and failed under the new rule, so it was replaced with `test_opened_respects_nearer_printed_expiry` and `test_opened_not_expiring_when_both_limits_are_far`.
- `beauty_shelf_app/integration_test/expiry_flows_test.dart` wording updated ("earlier (PAO) limit"); behaviour unchanged (form default expiry is +180d, so PAO remains the binding limit).
