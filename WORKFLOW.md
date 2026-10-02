# Beauty Shelf - Workflow Guide

## Быстрый старт

Приложение **Android-only** и работает локально. Backend опционален.

```bash
# 1. Запустить приложение на эмуляторе
flutter emulators --launch BeautyShelf
cd beauty_shelf_app && flutter run -d emulator-5554

# 2. (Опционально) Поднять backend
docker-compose up -d
# Backend API: http://localhost:8000
# Swagger:     http://localhost:8000/docs
```

## Локальная разработка

### Android app (Flutter)
```bash
cd beauty_shelf_app

# Запуск на эмуляторе
flutter emulators --launch BeautyShelf
flutter run -d emulator-5554

# Или с выбором устройства
flutter devices
flutter run -d <device_id>
```

### Backend (FastAPI, опционально)
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

## Тесты

```bash
# Flutter: unit/widget (headless)
cd beauty_shelf_app
flutter test

# Flutter: integration (на устройстве)
flutter test integration_test/theme_categories_test.dart -d emulator-5554

# Backend тесты
cd backend
source venv/bin/activate
pip install -r requirements-test.txt
pytest ../tests/ -v

# Или из корня
docker-compose exec backend pytest /app/tests/ -v
```

## Docker команды

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Логи
docker-compose logs -f backend

# Пересборка
docker-compose up -d --build

# Полный reset
docker-compose down -v
docker-compose up -d --build
```

## Структура Docker

```
┌─────────────────────────────────────────────────┐
│                  python:3.12-slim                │
│  Backend API (port 8000)                         │
│  ┌─────────────────────────────────────────┐   │
│  │  FastAPI + SQLite (/app/data/)           │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

Мобильное приложение запускается отдельно через Flutter и backend не требует.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products` | Все продукты |
| GET | `/api/products?type=care` | По типу |
| POST | `/api/products` | Создать |
| PUT | `/api/products/{id}` | Обновить |
| DELETE | `/api/products/{id}` | Удалить |
| GET | `/api/products/search/{query}` | Поиск |
| GET | `/api/expiring?days=7` | Истекающие |
| GET | `/api/health` | Health check |

## Развёртывание

### Локально (Docker + APK)
```bash
# Android APK
cd beauty_shelf_app && flutter build apk --release && cd ..
# → beauty_shelf_app/build/app/outputs/flutter-apk/app-release.apk

# Backend
docker-compose up -d --build
```

### На сервере
```bash
git pull
docker-compose up -d --build
```

### Удалённый доступ
```bash
# Backend
http://YOUR_IP:8000
```

## Файлы

```
beauty_shelf/
├── backend/
│   ├── main.py           # FastAPI app
│   ├── Dockerfile
│   └── requirements.txt
├── beauty_shelf_app/     # Flutter Android app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   ├── test/                 # Unit + widget tests
│   ├── integration_test/     # On-device tests
│   └── pubspec.yaml
├── tests/
│   └── test_api.py      # pytest tests
├── docker-compose.yml
└── deploy.sh
```

## Flutter структура

```
beauty_shelf_app/lib/
├── main.dart              # App entry point
├── models/
│   └── product.dart      # Product model + categories
├── services/
│   ├── storage_service.dart      # Storage interface
│   ├── storage_io.dart           # MobileStorageService (SQLite)
│   ├── storage_factory.dart      # Returns mobile storage
│   ├── api_service.dart          # Public barcode APIs
│   ├── database_service.dart
│   └── notification_service.dart
├── screens/
│   ├── home_screen.dart          # Main product list
│   ├── settings_screen.dart      # Theme + categories
│   └── barcode_scanner_screen.dart
├── theme/
│   └── app_theme.dart    # Theme singleton + SharedPreferences
├── utils/
│   └── sorting.dart
└── widgets/
    ├── product_card.dart     # Product card widget
    └── product_form.dart     # Add/Edit form
```
