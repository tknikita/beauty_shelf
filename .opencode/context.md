# Project Context

## Environment
- Language: Dart 3.11+ (Flutter 3.41.8)
- Frontend: Flutter Web (Material Design 3)
- Backend: FastAPI + SQLite (Python 3.12)
- Build: `flutter build web --release`
- Test: `pytest tests/ -v`

## Project Type
- Application (Flutter Web frontend + FastAPI backend)
- Docker-based deployment: nginx:alpine + python:3.12-slim

## Infrastructure
- Container: Docker Compose (backend + frontend)
- Nginx serves static files + proxies /api/* → backend:8000
- CI/CD: Manual deploy.sh

## Structure
- Frontend: beauty_shelf_app/ (Flutter)
  - lib/main.dart — Entry point
  - lib/models/ — Data models
  - lib/services/ — API service
  - lib/screens/ — Screen widgets
  - lib/widgets/ — Reusable widgets
  - lib/theme/ — Theme configuration
- Backend: backend/ (FastAPI)
- Tests: tests/
- Build output: beauty_shelf_app/build/web/

## Conventions
- Naming: snake_case for files, camelCase for Dart code
- API: RESTful, /api/* prefix
- Database: SQLite with simple row queries
- Theme: Global singleton AppTheme with ChangeNotifier

## Current Status
- Flutter web app deployed at localhost:8080
- Material Design 3 with customizable theme
- Features: Products CRUD, barcode lookup, image upload, export/import JSON
