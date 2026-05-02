# Beauty Shelf - Technical Specification

## Overview

Cross-platform cosmetics inventory tracker with Flutter (web + Android) frontend and FastAPI backend.

**Platforms:**
- **Web** - Flutter web app served via Nginx, uses backend API
- **Android** - Flutter Android APK with local SQLite storage (offline-capable)

## Architecture

```
┌──────────────────┐     HTTP         ┌─────────────────┐
│  Nginx (Port 80) │ ───────────────► │  FastAPI (8000) │
│  + Flutter Web   │                  │  + SQLite        │
└──────────────────┘                  └─────────────────┘
         │
         ├── Serves: Flutter web app
         ├── Proxy: /api/* → backend:8000
         └── Proxy: /ws → backend:8000 (WebSocket)
```

## Components

### Frontend (Flutter Web)
- Flutter 3.x with Material Design 3
- Reactive theme system with localStorage persistence
- 6 color presets: Розовый, Лаванда, Мята, Персик, Голубой, Монохром
- Product cards with status badges
- Table view with sortable columns
- Filter by type (All / Care / Decorative)
- Search by name or purpose
- Add/Edit/Delete products
- Barcode lookup via Open Beauty Facts API
- Directory: `beauty_shelf_app/`

### Android App (Flutter Mobile)
- Flutter 3.x with Material Design 3
- Local SQLite storage (offline-capable)
- **Local image storage** - picked photos saved to app documents
- Same UI as web with responsive layout
- Navigation bar safe area handling
- APK: `beauty_shelf_app/build/app/outputs/flutter-apk/app-debug.apk`

### Backend (FastAPI)
- Port: 8000
- Database: SQLite (`beauty_shelf.db`)
- Endpoints:
  - `GET /api/products` - List all (optional `?type=care|decorative`)
  - `POST /api/products` - Create
  - `GET/PUT/DELETE /api/products/{id}` - CRUD
  - `GET /api/products/search/{query}` - Search by name/purpose
  - `GET /api/expiring?days=7` - Expiring items
  - `GET /api/health` - Health check

### Database Schema
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT CHECK(type IN ('care', 'decorative')),
    category TEXT NOT NULL,
    purpose TEXT,
    expiry_date DATE NOT NULL,
    is_opened INTEGER DEFAULT 0,
    opened_date DATE,
    expiry_days_after_open INTEGER DEFAULT 30,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Docker Configuration

### Services
1. **backend** - Python + FastAPI + SQLite
2. **frontend** - Nginx Alpine + Flutter web build

### Docker Commands
```bash
# Start services
docker-compose up -d

# Rebuild frontend
cd beauty_shelf_app && flutter build web
docker-compose build frontend
docker-compose up -d frontend

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

## Features

### Frontend Features
- **Reactive Theme System** - 6 color presets with localStorage persistence
- Product cards with expiry status badges
- **Table view** with sortable columns (Name, Type, Category, Expiry, Status)
- Filter by type (All / Care / Decorative)
- Filter by category (dropdown with all categories grouped by type)
- Filter by expiry status (All / Просрочено / < 30 дн. / < 60 дн. / OK)
- View toggle (cards ↔ table)
- Search by name or purpose
- Add/Edit/Delete products
- **Opened product tracking** (date opened + expiry after opening)
- **Barcode scanner** with manual input
- **Auto-fill from Open Beauty Facts / Open Food Facts API**
- Responsive design (mobile + desktop)
- Combined filtering (filters work together)

### Theme System
The app uses a reactive theme system:
- Static singleton `AppTheme` class extending `ChangeNotifier`
- Theme changes trigger rebuild of all listening widgets
- Settings saved to `localStorage` and restored on app start
- 6 preset themes available in Settings screen

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

### Expiry Status Logic
- **OK** (>60 days): Green badge
- **Warning** (30-60 days): Orange badge
- **Danger** (<30 days): Red badge
- **Expired** (<0 days): Red badge with "Просрочено"

### Opened Product Tracking
When a product is marked as "opened":
- Store `opened_date` and `expiry_days_after_open` (default 30 days)
- Calculate effective expiry: `opened_date + expiry_days_after_open`
- If no `opened_date`, fall back to original `expiry_date`
- Display "Вскрыто X дн. назад" badge on product cards

### Barcode Scanner
- Manual barcode input with lookup trigger
- Auto-fill from Open Beauty Facts API (https://world.openbeautyfacts.org/api/v2/)
- Fallback to Open Food Facts API (https://world.openfoodfacts.org/api/v2/)
- Auto-detect product type (care/decorative) from categories

## Project Structure

```
beauty_shelf/
├── SPEC.md                 # This file
├── docker-compose.yml      # Container orchestration
├── nginx.conf             # Nginx config
├── backend/
│   ├── main.py            # FastAPI application
│   ├── requirements.txt   # Python deps
│   └── Dockerfile          # Backend container
├── beauty_shelf_app/       # Flutter app (web + Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/product.dart
│   │   ├── services/
│   │   │   ├── api_service.dart      # Web: backend API client
│   │   │   ├── storage_service.dart   # Interface for storage
│   │   │   └── storage_io.dart       # Android: SQLite implementation
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── theme/app_theme.dart
│   │   └── widgets/
│   │       ├── product_card.dart
│   │       ├── product_table.dart
│   │       ├── product_form.dart
│   │       └── barcode_scanner.dart
│   └── pubspec.yaml
└── backend.db             # SQLite database (in container)
```

## Development

```bash
# Install Flutter
brew install flutter

# Edit frontend
cd beauty_shelf_app

# Run locally (web)
flutter run -d chrome

# Build web
flutter build web

# Build Android APK
flutter build apk --debug
flutter build apk --release

# Install on device (via USB)
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Deploy (web only)
docker-compose build frontend
docker-compose up -d frontend
```

## Changelog

### 2026-05-01
- **Added Android APK support** with local SQLite storage
  - Flutter app now builds for both web and Android
  - Android version uses `MobileStorageService` with local SQLite
  - Web version uses `ApiService` for backend communication
  - Offline barcode lookup and image upload (shows message instead)
  - Fixed UI layout issues: status bar overlap, card overlap, navigation bar safe areas
  - Supports gesture navigation on modern Android devices

### 2026-04-29
- **Fixed Table View** - Rows now render correctly with styling on Flutter Web
- **Fixed expiry filter** - Separate chips for < 30 days, < 60 days (no more toggling bug)

### 2026-04-28
- **Replaced HTML frontend** with Flutter web app
  - Material Design 3 UI with reactive theme system
  - Theme colors saved to localStorage and restored on reload
  - 6 color presets available in Settings screen
  - Table view with sortable columns
  - Barcode lookup with Open Beauty Facts API

### 2026-04-27
- **Replaced Flet frontend** with pure HTML/CSS/JS
  - Flet + Pyodide had rendering issues in browser
  - New frontend is lightweight (~30KB vs ~3MB)
  - No framework dependencies
- Simplified nginx.conf
- Simplified Dockerfile.frontend
