# Proposal

## Why

For an opened product the app currently computes the effective expiry as
`opened_date + PAO` and completely ignores the manufacturer's printed
`expiry_date`. When PAO reaches further than the printed date, the app reports a
product as usable long after its absolute shelf life has passed. The printed
date and PAO are two independent limits, and a product is fit for use only while
**both** still hold, so the effective expiry must be the **earlier** of the two.

## What Changes

- **BREAKING (behavioral)**: For an opened product with a known open date, the
  effective expiry becomes `min(expiry_date, opened_date + expiry_days_after_open)`
  instead of always `opened_date + PAO`. PAO can no longer extend the effective
  expiry beyond the manufacturer's printed date.
- Unchanged fallbacks: not opened → printed `expiry_date`; opened without a date
  → printed `expiry_date`; PAO-only / no printed date → `opened_date + PAO`.
- `daysLeft` and the status badge (OK / warning / danger / expired) derive from
  the corrected effective date.
- Add a small UI indication of **which limit is binding** on product cards
  (expiry-after-opening vs manufacturer expiry), so a product that is good by PAO
  but past the printed date is not silently mislabelled.
- The expiring-products SQL in the mobile storage layer and the optional backend
  mirror the same `min()` logic, so filter/notification results stay consistent
  with the model.
- Update `SPEC.md` to state the precedence explicitly, and replace the two tests
  that currently assert "PAO overrides a far printed expiry" with tests asserting
  the `min()` rule.
- No database schema change and no new dependencies.

## Capabilities

### New Capabilities
- `product-expiry`: the rules that derive a product's effective expiry date,
  remaining days, and status from the manufacturer's printed expiry date and the
  period-after-opening (PAO).

### Modified Capabilities
<!-- None: the project has no existing specs yet. -->

## Impact

- `beauty_shelf_app/lib/models/product.dart` — `effectiveExpiryDate`, `daysLeft`
- `beauty_shelf_app/lib/widgets/product_card.dart` — date text and binding-limit label
- `beauty_shelf_app/lib/services/storage_io.dart` — expiring-products SQL
- `backend/main.py` — expiring query SQL and docstring
- `beauty_shelf_app/test/product_test.dart` — flip the PAO-wins tests to min()
- `SPEC.md` — document the precedence rule
- No API, dependency, or schema changes.
