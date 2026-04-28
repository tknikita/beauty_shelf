# Beauty Shelf - Flutter Frontend Issues

## Current State (28.04.2026)
- Flutter 3.41.8 web app deployed at localhost:8080
- Uses Material Design 3 with pink theme (E8B4BC)

## Issues to Fix

### 1. Table View Not Working
**File:** `beauty_shelf_app/lib/screens/home_screen.dart`
**Problem:** Toggle between grid/table view doesn't work properly
**Fix needed:** Ensure state is properly managed, ProductTable widget works

### 2. Theme Changes Incomplete
**File:** `beauty_shelf_app/lib/theme/app_theme.dart`
**Problem:** Only some elements use AppTheme colors, others hardcoded
**Fix needed:** Update all widgets to use AppTheme colors

### 3. Manual Color Input Missing
**File:** `beauty_shelf_app/lib/screens/settings_screen.dart`
**Problem:** Only presets available, no custom color picker
**Fix needed:** Add color picker (HEX input or color wheel)

### 4. Settings Screen Too Large
**File:** `beauty_shelf_app/lib/screens/settings_screen.dart`
**Problem:** Grid of presets takes too much space
**Fix needed:** Make it more compact

## Plan (Step by Step)

1. [x] Fix table view toggle ✓ `c1a92aa`
2. [ ] Make all widgets use AppTheme colors
3. [ ] Commit: "fix: use AppTheme colors consistently"
4. [ ] Add manual HEX color input
5. [ ] Commit: "feat: add custom color picker"
6. [ ] Make settings screen more compact
7. [ ] Commit: "fix: compact settings screen"

## Current File Structure
```
beauty_shelf_app/
├── lib/
│   ├── main.dart
│   ├── models/product.dart
│   ├── services/api_service.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   └── settings_screen.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── product_card.dart
│       ├── product_form.dart
│       ├── product_table.dart
│       └── barcode_scanner.dart
```
