# Beauty Shelf - Workflow Guide

## Сессия работы

### Перед началом
```bash
cd beauty_shelf
```

### Запуск проекта

**Терминал 1 - Backend:**
```bash
cd backend
source venv/bin/activate
uvicorn main:app --reload --port 8000
```

**Терминал 2 - Frontend:**
```bash
cd frontend
source venv/bin/activate
python main.py
```

### Проверка работы API
```bash
# Все продукты
curl http://localhost:8000/api/products

# Добавить продукт
curl -X POST http://localhost:8000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Крем","type":"care","category":"face_cream","purpose":"Увлажнение","expiry_date":"2025-12-01"}'

# Продукты по типу
curl http://localhost:8000/api/products?type=care
```

## Типичные задачи

### Добавить новую фичу
1. Изменить `backend/main.py` для API
2. Изменить `frontend/api.py` для клиента
3. Изменить `frontend/main.py` для UI
4. Перезапустить backend

### Исправить баг
1. Проверить логи backend в терминале
2. Проверить консоль Flet
3. Исправить
4. Перезапустить нужную часть

### Обновить категории
1. Изменить `frontend/categories.py`
2. Перезапустить frontend

## Git workflow

```bash
# Проверить изменения
git status

# Закоммитить
git add -A
git commit -m "feat: описание"

# Посмотреть историю
git log --oneline -5
```

## Ошибки и решения

| Проблема | Решение |
|----------|--------|
| "Module not found" | Перезапустить backend |
| Фронт не видит данные | Проверить что backend на порту 8000 |
| Flet ошибка | Проверить импорты, перезапустить |
| API вернул ошибку | Проверить логи uvicorn |

## Структура файлов

```
beauty_shelf/
├── backend/
│   ├── main.py      # FastAPI app, endpoints
│   ├── requirements.txt
│   └── beauty_shelf.db  # SQLite (создаётся)
├── frontend/
│   ├── main.py     # Flet UI
│   ├── api.py      # HTTP клиент
│   └── categories.py
└── README.md
```

## Консольные команды

```bash
# Backend
uvicorn main:app --reload --port 8000  # с hot reload
uvicorn main:app --host 0.0.0.0 --port 8000  # для доступа с телефона

# Frontend
python main.py  # desktop
flet build web .  # веб билд

# Тесты API
curl http://localhost:8000/docs  # Swagger UI
curl http://localhost:8000/redoc  # ReDoc
```
