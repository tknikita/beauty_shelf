# Beauty Shelf - Косметика Трекер

Кроссплатформенное приложение для учёта косметики с отслеживанием сроков годности.

## Архитектура

```
┌─────────────┐     HTTP      ┌─────────────┐
│   Frontend  │ ◄────────────► │   Backend   │
│   (Flet)   │   localhost    │  (FastAPI)  │
│   + httpx   │               │   +SQLite   │
└─────────────┘               └─────────────┘
```

## Быстрый старт

### 1. Запуск бэкенда
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 2. Запуск фронтенда (отдельный терминал)
```bash
cd ../frontend
# Установите зависимости вручную или используйте системный pip
pip install flet httpx
python main.py
```

### 3. Веб-версия (в разработке)
```bash
cd ../frontend
pip install flet httpx
flet build web .
python3 -m http.server 8080 --directory build/web
```

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
| GET | `/api/settings/{key}` | Настройка |
| PUT | `/api/settings/{key}` | Сохранить настройку |

## Структура проекта

```
beauty_shelf/
├── backend/
│   ├── main.py           # FastAPI app
│   ├── requirements.txt   # Python deps
│   └── beauty_shelf.db   # SQLite DB (создаётся)
├── frontend/
│   ├── main.py           # Flet app
│   ├── api.py            # API client
│   └── categories.py     # Категории
├── SPEC.md              # Спецификация
└── CONTRIBUTING.md      # Гайд по разработке
```

## Возможности

- ✅ Учёт уходовой и декоративной косметики
- ✅ Категории продуктов
- ✅ Отслеживание сроков годности
- ✅ Фильтрация и поиск
- ✅ Настройки уведомлений
- ✅ Кроссплатформенность (Desktop/Web/Mobile)

## Технологии

**Frontend:** Flet (Flutter), Python 3.10+  
**Backend:** FastAPI, SQLite, Uvicorn  
**API:** REST, JSON

## TODO

- [ ] Аутентификация пользователей
- [ ] Синхронизация между устройствами
- [ ] Push-уведомления (Firebase)
- [ ] PWA для мобильных
