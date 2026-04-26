# Beauty Shelf - Workflow Guide

## Быстрый старт (Docker)

```bash
# 1. Собрать и запустить
docker-compose up -d --build

# 2. Открыть
# Backend API: http://localhost:8000
# Frontend:    http://localhost:8080
# Swagger:     http://localhost:8000/docs
```

## Локальная разработка

### Backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Frontend (Desktop)
```bash
cd frontend
source venv/bin/activate
python main.py
```

## Тесты

```bash
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
docker-compose logs -f frontend

# Пересборка
docker-compose up -d --build

# Полный reset
docker-compose down -v
docker-compose up -d --build
```

## Структура Docker

```
┌─────────────────────────────────────────────────┐
│                   nginx:alpine                  │
│  Frontend (port 8080)                         │
│  ┌─────────────────────────────────────────┐ │
│  │  SPA routing + API proxy (/api → backend) │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────┘ │
                      │ proxy_pass
                      ▼
┌─────────────────────────────────────────────────┐
│               python:3.12-slim                   │
│  Backend API (port 8000)                         │
│  ┌─────────────────────────────────────────┐   │
│  │  FastAPI + SQLite (/app/data/)           │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
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
| GET | `/api/health` | Health check |

## Развёртывание

### Локально (Docker)
```bash
./deploy.sh
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

# Frontend  
http://YOUR_IP:8080
```

## Файлы

```
beauty_shelf/
├── backend/
│   ├── main.py           # FastAPI app
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/
│   ├── main.py          # Flet UI
│   ├── api.py           # API client
│   └── requirements.txt
├── tests/
│   └── test_api.py      # pytest tests
├── docker-compose.yml
├── Dockerfile.frontend
├── nginx.conf
└── deploy.sh
```
