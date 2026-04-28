# Beauty Shelf - TODO

## Done ✓
- [x] Table view toggle fix
- [x] Theme changes apply to all widgets (ProductCard, ProductTable, etc.)
- [x] Theme persists after page reload (localStorage)
- [x] Settings screen shows theme changes immediately (ListenableBuilder)

## Pending

### High Priority
- [x] Manual HEX color input in settings
  - [x] Allow users to enter custom colors
  - [x] Color picker or HEX input field
  - [x] Validate color format (#RRGGBB)
  - [x] Clickable color palette (tabs for primary/background)

### Medium Priority
- [x] Compact settings screen layout
  - [x] Horizontal scrollable presets
  - [x] Smaller preset cards (64px circular swatches)
  - [x] Compact HEX inputs side by side

### Low Priority / Ideas
- [ ] Camera-based barcode scanning (Web BarcodeDetector API)
- [ ] Dark mode support
- [ ] Product categories custom management
- [ ] Export/Import data (JSON/CSV)
- [ ] Notifications for expiring products
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
