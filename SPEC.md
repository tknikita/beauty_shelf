# Beauty Shelf - Technical Specification

## Overview

Mobile-only (Android) cosmetics inventory tracker. The Flutter Android app is local-first and needs no server to run; the FastAPI backend stays in the repo as an optional standalone service.

- **App name:** Полочка
- **Flutter package:** `polochka`
- **Android applicationId:** `com.beautyshelf.beauty_shelf_app`
- **Version:** `0.1.2+3`
- **Repository:** https://github.com/tknikita/beauty_shelf
- **Latest release:** `v0.1.2`

**Platform:** Android only. The Flutter Web build, the Nginx-served frontend, and all web-specific code paths have been removed.

## Architecture

Local-first: the mobile app owns all of its data and does not call the backend.

```
┌─────────────────────────────────────┐
│  Flutter Android app (Полочка)      │
│  ┌───────────────────────────────┐  │
│  │ UI (Material 3)                │  │
│  ├───────────────────────────────┤  │
│  │ MobileStorageService           │  │
│  │  • SQLite (beauty_shelf.db)    │  │
│  │  • images/ (app documents dir) │  │
│  │  • SharedPreferences (settings)│  │
│  └───────────────────────────────┘  │
└──────────────────┬──────────────────┘
                   │ HTTPS — barcode lookup only
                   ▼
   Open Beauty Facts / Open Food Facts public APIs

┌─────────────────────────────────────┐
│  FastAPI backend (optional)         │
│  docker-compose → port 8000         │
│  Not used by the mobile app         │
└─────────────────────────────────────┘
```

## Components

### Android App (Flutter Mobile)
- Flutter 3.x with Material Design 3
- **Local SQLite** via `sqflite` — DB file `beauty_shelf.db`, schema version 2; `onUpgrade` adds `notification_days`
- **Local image storage** — picked photos saved to the app documents directory under `images/`
- Settings (theme, dark mode, custom categories, removed categories) persisted in `SharedPreferences`
- **Storage abstraction:**
  - `storage_service.dart` — the `StorageService` interface
  - `storage_io.dart` — `MobileStorageService` (sqflite + filesystem)
  - `storage_factory.dart` — returns the mobile implementation (no conditional web imports)
- Barcode lookup calls public APIs directly via `api_service.dart` (no backend involvement)
- Same product UI as before: cards, table view, filters, search
- Navigation bar safe area handling
- Directory: `beauty_shelf_app/`
- APK: `beauty_shelf_app/build/app/outputs/flutter-apk/app-release.apk`

### Backend (FastAPI, optional)
- Port: 8000
- Database: SQLite (`beauty_shelf.db`)
- Remains in the repo as a separate/optional service run via `docker-compose`. It is **not required** to run the mobile app and the app does not call it.
- Endpoints:
  - `GET /api/products` - List all (optional `?type=care|decorative`)
  - `POST /api/products` - Create
  - `GET/PUT/DELETE /api/products/{id}` - CRUD
  - `GET /api/products/search/{query}` - Search by name/purpose
  - `GET /api/expiring?days=7` - Expiring items
  - `GET /api/health` - Health check

### Database Schema (mobile app, version 2)
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    category TEXT NOT NULL,
    purpose TEXT,
    expiry_date TEXT NOT NULL,
    is_opened INTEGER DEFAULT 0,
    opened_date TEXT,
    expiry_days_after_open INTEGER DEFAULT 30,
    image_url TEXT,
    notification_days INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

Migration: `onUpgrade` from v1 → v2 runs `ALTER TABLE products ADD COLUMN notification_days INTEGER`.

The FastAPI backend keeps its own separate schema.

## Docker Configuration

### Services
1. **backend** - Python + FastAPI + SQLite

The former `frontend` (Nginx + Flutter web) service and port 8080 have been removed.

### Docker Commands
```bash
# Start backend
docker-compose up -d

# Rebuild backend
docker-compose build backend
docker-compose up -d backend

# View logs
docker-compose logs -f backend
```

## Features

### App Features
- **Reactive Theme System** - 6 color presets with `SharedPreferences` persistence
- Product cards with expiry status badges
- **Table view** with sortable columns (Name, Type, Category, Expiry, Status)
- Filter by type (All / Care / Decorative)
- Filter by category (dropdown with all categories grouped by type)
- Filter by expiry status (All / Просрочено / < 30 дн. / < 60 дн. / OK)
- View toggle (cards ↔ table)
- Search by name or purpose
- Add/Edit/Delete products
- **Opened product tracking** (date opened + expiry after opening)
- **Barcode scanner** with manual input (camera on mobile)
- **Auto-fill from Open Beauty Facts / Open Food Facts API**
- **Expiry notifications** with per-product timing (`notification_days`)
- **Category management** — add custom categories, remove built-ins
- Navigation bar safe area handling

### Theme System
The app uses a reactive theme system:
- Static singleton `AppTheme` class extending `ChangeNotifier`
- Theme changes trigger a rebuild of all listening widgets
- Settings saved to `SharedPreferences` and restored on app start
- Storage keys: `beauty_shelf_theme`, `beauty_shelf_dark`, `beauty_shelf_categories`, `beauty_shelf_removed_categories`
- 6 preset themes available in the Settings screen

### Categories

#### Care (Уходовая)
| Key | Name |
|-----|------|
| basic_care | Базовая уходовая |
| cleanser | Очищение |
| tonic | Тоник |
| serum | Сыворотка |
| cream | Крем |
| face_cream | Крем для лица |
| eye_cream | Крем для глаз |
| mask | Маска |
| sunscreen | Солнцезащита |
| special | Специальный уход |

#### Decorative (Декоративная)
| Key | Name |
|-----|------|
| base | База |
| tone | Тональное средство |
| concealer | Консилер |
| powder | Пудра |
| blush | Румяна |
| bronzer | Бронзер |
| highlighter | Хайлайтер |
| eyeshadow | Тени для век |
| eyeliner | Подводка |
| mascara | Тушь |
| eyebrows | Брови |
| lips | Губы |
| nails | Ногти |

**Built-in categories can be removed.** The removal is persisted under the `beauty_shelf_removed_categories` key; removing a built-in hides it, and re-adding a category with the same key restores it.

### Expiry Status Logic
- **OK** (>60 days): Green badge
- **Warning** (30-60 days): Orange badge
- **Danger** (<30 days): Red badge
- **Expired** (<0 days): Red badge with "Просрочено"

### Opened Product Tracking
When a product is marked as "opened":
- Store `opened_date` and `expiry_days_after_open` (PAO, default 30 days)
- The printed `expiry_date` and the PAO limit (`opened_date + expiry_days_after_open`) are two independent constraints; the **effective expiry is the earlier of the two**
- PAO **never extends** the effective expiry past the manufacturer's printed `expiry_date`
- If no `opened_date`, the effective expiry falls back to the printed `expiry_date`
- Product cards show only the effective expiry date (`до DD.MM.YYYY`); `Product.expiryBasis` still exposes the binding limit on the model but it is not rendered on the card
- Product cards mark opened packages with the official PAO symbol (open jar; tooltip «Вскрыта упаковка») next to the status badge — vector asset `beauty_shelf_app/assets/icons/pao_symbol.svg`, rendered via `flutter_svg`

### Barcode Scanner
- Camera scanning (`mobile_scanner`) plus manual barcode input
- Lookup goes **directly** to public APIs from `api_service.dart`:
  - Open Beauty Facts (https://world.openbeautyfacts.org/api/v2/)
  - Open Food Facts (https://world.openfoodfacts.org/api/v2/)
  - French mirrors (`fr.openbeautyfacts.org`, `com.openfoodfacts.org`) + search fallback
- Auto-detect product type (care/decorative) from categories
- No FastAPI backend call

## Project Structure

```
beauty_shelf/
├── SPEC.md                 # This file
├── WORKFLOW.md             # Workflow guide
├── CONTRIBUTING.md         # Contributor guide
├── TODO.md                 # Task list
├── docker-compose.yml      # backend service only
├── deploy.sh               # builds Android APK + starts backend
├── backend/
│   ├── main.py             # FastAPI application (optional service)
│   ├── requirements.txt    # Python deps
│   └── Dockerfile          # Backend container
├── tests/
│   └── test_api.py         # Backend pytest tests
└── beauty_shelf_app/       # Flutter Android app
    ├── lib/
    │   ├── main.dart
    │   ├── models/product.dart
    │   ├── services/
    │   │   ├── storage_service.dart       # Storage interface
    │   │   ├── storage_io.dart            # MobileStorageService (sqflite)
    │   │   ├── storage_factory.dart       # Returns mobile storage
    │   │   ├── api_service.dart           # Public barcode APIs
    │   │   ├── database_service.dart
    │   │   └── notification_service.dart
    │   ├── screens/
    │   │   ├── home_screen.dart
    │   │   ├── settings_screen.dart
    │   │   └── barcode_scanner_screen.dart
    │   ├── theme/app_theme.dart
    │   ├── utils/sorting.dart
    │   └── widgets/
    │       ├── product_card.dart
    │       └── product_form.dart
    ├── test/                 # Unit + widget tests
    ├── integration_test/     # On-device tests
    └── pubspec.yaml
```

## Development

```bash
# Android toolchain (macOS, Homebrew)
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# Run on emulator
flutter emulators --launch BeautyShelf
cd beauty_shelf_app
flutter run -d emulator-5554        # or `flutter run` and pick a device

# Build release APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# Install on device (via USB)
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Tests
flutter test                                              # headless unit/widget
flutter test integration_test/theme_categories_test.dart -d emulator-5554   # on device

# Optional backend
docker-compose up -d
# API http://localhost:8000, Swagger http://localhost:8000/docs
```

## Changelog

### 2026-10-10
- **Corrected opened-product expiry precedence** — the effective expiry is now the **earlier** of the printed `expiry_date` and `opened_date + PAO`, so PAO can no longer extend a product past the manufacturer's printed date
- Product cards show only the effective expiry date (`до DD.MM.YYYY`); the `после вскрытия` / `срок производителя` labels were removed
- **Opened products are marked on the card** — the official PAO symbol (open jar) next to the status badge
- **Card layout reworked** — the overflow menu (⋮) sits in the top-right corner and, when quantity > 1, the `− N +` stepper in the bottom-right corner; both are drawn as overlays so they never widen the controls column — the name/subtitle keep their full width and the card height is the same whether or not the stepper is shown
- Expiring queries (mobile `storage_io.dart` and optional `backend/main.py`) apply the same `MIN(...)` rule

### 2026-10-02
- **Mobile-only release** — removed the Flutter Web build and all web-specific paths
  - Removed `beauty_shelf_app/web/`, `lib/services/storage_web.dart`, `api_service_web.dart`, `api_service_io.dart`
  - `docker-compose.yml` now runs only the `backend` service; the `frontend`/Nginx service and port 8080 were removed
  - `deploy.sh` now builds the Android APK (`flutter build apk --release`)
  - Removed the `http_parser` dependency
- **Fixed colour presets** — selecting a preset now changes the app background; `adjustColors()` no longer overwrites the chosen background
- **Built-in categories can be deleted** — persisted under `beauty_shelf_removed_categories`; re-adding the same key restores the category
- **Barcode lookup is backend-free** — the app calls Open Beauty Facts / Open Food Facts directly and no longer calls the FastAPI backend
- **Tests** — unit/widget tests in `beauty_shelf_app/test/` (incl. `app_theme_test.dart`) and on-device integration tests in `beauty_shelf_app/integration_test/` (`theme_categories_test.dart`, `expiry_flows_test.dart`, `app_test.dart`)

### 2026-05-01
- **Added Android support** with local SQLite storage
  - Android version uses `MobileStorageService` with local SQLite
  - Offline barcode lookup and local image storage
  - Fixed UI layout issues: status bar overlap, card overlap, navigation bar safe areas
  - Supports gesture navigation on modern Android devices
