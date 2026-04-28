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

### Medium Priority
- [ ] Compact settings screen layout
  - Current 2-column grid takes too much vertical space
  - Consider horizontal scrollable presets
  - Or smaller preset cards with color swatches only

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

## Tech Debt
- Remove `// ignore: avoid_web_libraries` for dart:html
- Consider migrating to `web` package instead of `dart:html`
- Add unit tests for theme system
