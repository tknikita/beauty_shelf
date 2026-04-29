# Beauty Shelf - TODO

## Done ✓
- [x] Table view toggle fix
- [x] Table view rows rendering (fixed styling issues on Flutter Web)
- [x] Theme changes apply to all widgets (ProductCard, ProductTable, etc.)
- [x] Theme persists after page reload (localStorage)
- [x] Settings screen shows theme changes immediately (ListenableBuilder)

## Pending

### High Priority
- [x] Manual HEX color input in settings
- [x] Expiry filter
  - Filter by status: Просрочено / < 30 дней / < 60 дней / OK
  - Quick-select chips in filter panel
- [ ] Product images
  - Add image upload to products
  - Display image in cards
  - Store images locally or via API
- [ ] Font customization
  - Font size selection (small/medium/large)
  - Persist in localStorage

### Medium Priority
- [x] Compact settings screen layout
- [x] Dark mode support

### Low Priority / Ideas
- [x] Barcode entry dialog
- [x] Export/Import data (JSON)
- [x] Notifications for expiring products (backend endpoint /api/expiring)
- [ ] Camera-based barcode scanning
- [ ] PWA support for offline mode
- [ ] Mobile native app (iOS/Android)

## Known Issues
- Flutter web WASM warnings (non-critical)
- Form deprecated `value` parameter warnings

## Tech Debt
- Remove `// ignore: avoid_web_libraries` for dart:html
- Consider migrating to `web` package instead of `dart:html`
- Add unit tests for theme system
