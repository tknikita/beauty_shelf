# Beauty Shelf - TODO

## Done ✓
- [x] Table view toggle fix
- [x] Theme changes apply to all widgets (ProductCard, ProductTable, etc.)
- [x] Theme persists after page reload (localStorage)
- [x] Settings screen shows theme changes immediately (ListenableBuilder)

## Pending

### High Priority
- [x] Manual HEX color input in settings
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
- [x] Notifications for expiring products
- [ ] Camera-based barcode scanning
- [ ] PWA support for offline mode
- [ ] Mobile native app (iOS/Android)

## Known Issues
- Flutter web WASM warnings (non-critical)
- Form deprecated `value` parameter warnings

## Table View Bug (UNRESOLVED)
Table view header renders but rows don't appear on Flutter Web. Minimal `Column` + `.map()` works, but adding styling/Container breaks rendering. Current implementation is minimal text-only version until proper layout solution found.

## Tech Debt
- Remove `// ignore: avoid_web_libraries` for dart:html
- Consider migrating to `web` package instead of `dart:html`
- Add unit tests for theme system
