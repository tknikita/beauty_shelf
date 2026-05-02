# Beauty Shelf - TODO

## Done (v1.0) ✓
- [x] Table view toggle fix
- [x] Table view rows rendering
- [x] Theme system with persistence
- [x] HEX color input in settings
- [x] Expiry filter with chips
- [x] Product images (local storage)
- [x] Barcode entry dialog
- [x] Export/Import JSON
- [x] Navigation bar safe area
- [x] Android platform support
- [x] Image optimization (cacheWidth/cacheHeight)

## Feature Branches

### branch: `feat/barcode-scanner`
**Camera-based barcode scanning (mobile)**
- [x] Integrate camera plugin (mobile_scanner)
- [x] Auto-fill barcode field after scan
- [x] Multi-source barcode lookup (Open Beauty/Food Facts)
- [x] Flash/torch toggle
- Status: DONE ✓

### branch: `feat/expiring-notifications`
**Push notifications for expiring products**
- [x] flutter_local_notifications for scheduled notifications
- [x] Daily check scheduled at 9 AM
- [x] Configurable notification timing (1/3/7/14/30 days before)
- [ ] Notification tap opens product (needs deep linking)
- Status: DONE ✓

### branch: `feat/pao-tracking`
**Period After Opening tracking**
- [ ] Add "opened" toggle with date picker in product form
- [ ] Calculate expiry from open date + PAO days
- [ ] Show PAO status in product card
- [ ] Settings: default PAO per category
- Status: TODO

### branch: `feat/swipe-actions`
**Swipe gestures on product cards**
- [x] Swipe left to delete (with confirmation)
- [x] Swipe right to edit
- [x] Visual feedback during swipe
- [x] Haptic feedback
- Status: DONE ✓

### branch: `feat/bulk-actions`
**Bulk operations**
- [ ] Multi-select mode toggle
- [ ] Select all / deselect all
- [ ] Bulk delete selected
- [ ] Bulk mark as opened
- Status: TODO

### branch: `feat/product-templates`
**Quick add from templates**
- [ ] Save current product as template
- [ ] List saved templates
- [ ] Quick-add from template (name, category, default PAO)
- [ ] Templates management in settings
- Status: TODO

## Low Priority
- [ ] PWA support for offline mode
- [ ] Cloud backup (Google Drive/iCloud)
- [ ] Voice input for product names
- [ ] Home screen widget
- [ ] Open Beauty Facts integration (expanded data)

## Tech Debt
- [ ] Remove dart:html, migrate to `web` package
- [ ] Fix deprecated `value` parameter in DropdownButtonFormField
- [ ] Add unit tests for theme system
- [ ] Add widget tests for ProductForm
