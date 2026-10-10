# Design

## Context

See `proposal.md` — Why. The current single source of truth for the effective
expiry is `Product.effectiveExpiryDate` in
`beauty_shelf_app/lib/models/product.dart`, which returns `opened_date + PAO`
for opened products and ignores the printed `expiry_date`. The same rule is
duplicated in two SQL queries (`storage_io.dart` and the optional
`backend/main.py`) and is asserted by two tests in `product_test.dart`.

## Goals / Non-Goals

**Goals:**
- Make the model getter the authoritative `min(printed, opened + PAO)` rule.
- Keep both SQL queries and the notification path consistent with the getter.
- Expose which limit is binding so the card can explain the date.
- Keep the change free of schema migrations and new dependencies.

**Non-Goals:**
- Changing the status thresholds or badge colours.
- Introducing per-category default PAO or editing PAO semantics.
- Touching web/desktop paths (the app is Android-only).

## Decisions

**1. Centralize the rule in `Product.effectiveExpiryDate`.**
`daysLeft` already delegates to this getter, so changing it here fixes cards,
filters, notifications, and tests at once. Alternative — compute in each widget
— was rejected because it duplicates the rule.

**2. Add a derived `expiryBasis` on the model.**
Introduce an enum (e.g. `ExpiryBasis.printedExpiry` /
`ExpiryBasis.periodAfterOpening` / `ExpiryBasis.none` when not opened) computed
from the same inputs as the getter. The card renders a short label from it.
Alternative — recompute in `product_card.dart` — was rejected to keep expiry
logic out of widgets.

**3. Mirror the rule in SQL with `MIN(...)`.**
The expiring queries cannot call Dart, so they use SQLite date arithmetic:
`MIN(expiry_date, date(opened_date, '+' || expiry_days_after_open || ' days'))`
when opened, otherwise `expiry_date`. This keeps filter and notification results
aligned with the getter. The backend query receives the same `MIN(...)` change
for parity even though the mobile app does not call it.

**4. Preserve null-safe fallbacks.**
Although the mobile schema declares `expiry_date NOT NULL`, keep a branch for a
missing printed date (PAO-only) so imported/backend payloads behave correctly:
opened + date + no printed date → `opened_date + PAO`.

**5. `effectiveExpiryDate` is compared using local date components.**
Reuse the existing pattern in `daysLeft` (truncate to `DateTime(y, m, d)`) so
dates are compared by calendar day, matching the SQL date-string comparison.

## Risks / Trade-offs

- [Products previously shown as "good" can flip to expired/soon] → Intended
  safety correction; call it out in `SPEC.md` and the changelog so behaviour is
  not mistaken for a regression.
- [Two existing tests assert PAO-wins] → Rewrite them to assert the `min()`
  rule; add explicit cases for both binding limits.
- [Dart `DateTime` arithmetic vs SQLite `date()` can disagree across time zones
  or DST] → Compare calendar-day date strings in both paths, as the current code
  already does; add a test for a same-day boundary.
- [Backend drift] → Update `backend/main.py` in the same change even though it is
  optional.

## Migration Plan

Pure code change; no database migration and no data backfill. Stored
`expiry_date`, `opened_date`, and `expiry_days_after_open` are unchanged, so the
corrected value is derived on read. Deploy by shipping a new APK. Rollback is a
revert of the commit — stored data stays valid either way.
