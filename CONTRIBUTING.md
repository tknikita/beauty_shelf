# Contributing to Beauty Shelf

## 🚀 Quick Start

Beauty Shelf is a **Flutter Android app** (mobile-only, local-first). The FastAPI backend is optional and the app does not depend on it.

### Dev setup (macOS, Homebrew)

```bash
# Android toolchain
brew install --cask android-commandlinetools
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools

# Export for emulator/adb
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# Clone and run
cd beauty_shelf/beauty_shelf_app
flutter pub get
flutter emulators --launch BeautyShelf
flutter run -d emulator-5554          # or `flutter run` and pick a device
```

### Build release APK

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Optional backend

```bash
docker-compose up -d
# API http://localhost:8000, Swagger http://localhost:8000/docs
```

`gh` (GitHub CLI) is used for releases.

## 📁 Project Structure

```
beauty_shelf/
├── backend/                # FastAPI (optional service)
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── tests/
│   └── test_api.py         # Backend pytest tests
├── beauty_shelf_app/       # Flutter Android app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/product.dart
│   │   ├── services/
│   │   │   ├── storage_service.dart   # Storage interface
│   │   │   ├── storage_io.dart        # MobileStorageService (SQLite)
│   │   │   ├── storage_factory.dart   # Returns mobile storage
│   │   │   ├── api_service.dart       # Public barcode APIs
│   │   │   ├── database_service.dart
│   │   │   └── notification_service.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   └── barcode_scanner_screen.dart
│   │   ├── theme/app_theme.dart
│   │   ├── utils/sorting.dart
│   │   └── widgets/
│   │       ├── product_card.dart
│   │       └── product_form.dart
│   ├── test/                   # Unit + widget tests
│   ├── integration_test/       # On-device tests
│   ├── android/
│   └── pubspec.yaml
├── docker-compose.yml          # backend service only
├── deploy.sh                   # builds Android APK + starts backend
├── SPEC.md
├── WORKFLOW.md
└── TODO.md
```

## 🎨 Design Guidelines

### Colors
- Primary: `#E8B4BC` (пыльная роза)
- Background: `#FDF9FA` (тёплый белый)
- Text: `#2D2D2D` (тёмно-серый)
- Secondary text: `#8A8A8A`

Colours live in the `AppTheme` singleton and are generated from the selected preset — do not hardcode theme colours in widgets.

### Typography
- Use `TextStyle` from the theme for body text
- `fontSize: 16-20` for headings
- `FontWeight.w600` for emphasis

### Spacing
- Card padding: 12-16px
- Grid gap: 12px
- Border radius: 12-16px

## 🧪 Testing

### Unit / widget (headless)
```bash
cd beauty_shelf_app
flutter test
```

### Integration (on a real device/emulator)
```bash
cd beauty_shelf_app
flutter test integration_test/theme_categories_test.dart -d emulator-5554
```

### Backend
```bash
cd backend
source venv/bin/activate
pip install -r requirements-test.txt
pytest ../tests/ -v
```

## 📱 Architecture (local-first)

| Data | Where it lives |
|------|----------------|
| Products | SQLite (`beauty_shelf.db`, schema v2) via `sqflite` |
| Images | App documents directory (`images/`) |
| Settings | `SharedPreferences` (`beauty_shelf_theme`, `beauty_shelf_dark`, `beauty_shelf_categories`, `beauty_shelf_removed_categories`) |
| Notifications | `flutter_local_notifications` |
| Barcode data | Open Beauty Facts / Open Food Facts public APIs |

The app never talks to the FastAPI backend. Keep all persistence behind the `StorageService` interface (`storage_service.dart`) and return the mobile implementation from `storage_factory.dart`. Do not add conditional web imports.

## 📝 Making Changes

1. **Analyze** - Run `flutter analyze` with no new warnings
2. **Test locally** - Run `flutter test` before committing
3. **Test on device** - For UI changes, run the integration tests on an emulator
4. **Keep storage abstracted** - New persistence goes through `StorageService`, never directly in widgets
5. **No web code** - The web build has been removed; do not reintroduce `dart:html`, conditional web imports, or web-only storage

## ⚠️ Common Issues

### "No Android SDK found"
→ Run `flutter config --android-sdk /opt/homebrew/share/android-commandlinetools`

### "adb: command not found" / emulator not listed
→ Export `ANDROID_HOME` and add `emulator` + `platform-tools` to `PATH` (see Quick Start)

### No emulator to run on
→ Launch the AVD first: `flutter emulators --launch BeautyShelf`

### `sqflite` unsupported / MissingPluginException
→ `sqflite` only works on mobile; keep logic behind `StorageService` and mock it in tests

### Notifications not appearing
→ Check notification permissions and that `flutter_local_notifications` is initialized

## 🏷️ Versioning

Releases are cut as git tags (current: `v0.1.2`) and published with GitHub CLI.

```bash
# Create a version tag
git tag -a v0.1.3 -m "New features"
git push origin main --tags

# Publish a release (optional)
gh release create v0.1.3
```
