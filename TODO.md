# Beauty Shelf - TODO

> Приложение **Android-only** (Flutter). Web-версия удалена; backend опционален.

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
- [x] Fix: выбор цветового пресета меняет фон приложения (adjustColors больше не перезаписывает выбранный фон)
- [x] Удаление встроенных категорий (persist в `beauty_shelf_removed_categories`; повторное добавление того же ключа возвращает категорию)
- [x] Unit/widget тесты (`test/`, включая `app_theme_test.dart`)
- [x] On-device integration тесты (`integration_test/`)

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

### branch: `feat/per-product-notifications`
**Per-product notification timing**
- [x] Add notification_days field to Product model
- [x] Text input field in product form
- [x] Schedule/cancel per-product notifications
- [x] DB migration for notification_days column
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
- [x] Tap to edit (restored)
- Status: DONE ✓

### branch: `feat/camera-image`
**Camera option for image upload**
- [x] Dialog with camera/gallery choice
- [x] Image compression (imageQuality: 80, maxWidth: 800)
- Status: DONE ✓

### branch: `feat/ui-fixes`
**UI fixes and improvements**
- [x] Sort categories alphabetically in product form
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
- [ ] Cloud backup (Google Drive/iCloud)
- [ ] Voice input for product names
- [ ] Home screen widget
- [ ] Open Beauty Facts integration (expanded data)

## Tech Debt
- [x] ~~Remove dart:html, migrate to `web` package~~ — web-версия удалена, задача неактуальна
- [ ] Fix deprecated `value` parameter in DropdownButtonFormField
- [x] Add unit tests for theme system (`app_theme_test.dart`)
- [ ] Add widget tests for ProductForm
