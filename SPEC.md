# Beauty Shelf - Technical Specification

## Overview

Cross-platform cosmetics inventory tracker with web frontend and FastAPI backend.

## Architecture

```
┌──────────────────┐     HTTP         ┌─────────────────┐
│  Nginx (Port 80) │ ───────────────► │  FastAPI (8000) │
│  + Static HTML   │                  │  + SQLite        │
└──────────────────┘                  └─────────────────┘
         │
         ├── Serves: index.html (static HTML/CSS/JS)
         ├── Proxy: /api/* → backend:8000
         └── Proxy: /ws → backend:8000 (WebSocket)
```

## Components

### Frontend (Static HTML/CSS/JS)
- Pure HTML/CSS/JavaScript (no framework dependencies)
- Responsive design with CSS Grid
- Modern UI with Inter font
- File: `frontend/index.html`

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
2. **frontend** - Nginx Alpine + Static HTML

### Nginx Configuration (nginx.conf)
```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://backend:8000;
    }
    
    location /ws {
        proxy_pass http://backend:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Docker Commands
```bash
# Start services
docker-compose up -d

# Rebuild frontend
docker-compose build frontend
docker-compose up -d frontend

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

## Features

### Frontend Features
- Product cards with expiry status (OK/Warning/Expired)
- **Table view** with sortable columns (Name, Type, Category, Expiry, Status)
- Filter by type (All / Care / Decorative)
- **Filter by category** (dropdown with all categories grouped by type)
- **Filter by expiry status** (All / OK / Soon / Very Soon / Expired)
- View toggle (cards ↔ table)
- Search by name or purpose
- Add/Edit/Delete products
- **Opened product tracking** (date opened + expiry after opening)
- **Barcode scanner** with camera and manual input
- **Auto-fill from Open Beauty Facts / Open Food Facts API**
- Responsive design (mobile + desktop)
- Combined filtering (filters work together)

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
- **OK** (>60 days): Green badge ✓ OK
- **Warning** (30-60 days): Orange badge ⚠
- **Danger** (<30 days): Red badge ⚠
- **Expired** (<0 days): Red badge ✗

### Opened Product Tracking
When a product is marked as "opened":
- Store `opened_date` and `expiry_days_after_open` (default 30 days)
- Calculate effective expiry: `opened_date + expiry_days_after_open`
- If no `opened_date`, fall back to original `expiry_date`
- Display "📅 Вскрыто X дн. назад" badge on product cards

### Barcode Scanner
- Camera-based scanning using BarcodeDetector API
- Manual barcode input with Enter key or blur trigger
- Auto-fill from Open Beauty Facts API (https://world.openbeautyfacts.org/api/v2/)
- Fallback to Open Food Facts API (https://world.openfoodfacts.org/api/v2/)
- Auto-detect product type (care/decorative) from categories

## Project Structure

```
beauty_shelf/
├── SPEC.md                 # This file
├── docker-compose.yml      # Container orchestration
├── Dockerfile.frontend      # Frontend container
├── nginx.conf             # Nginx config
├── backend/
│   ├── main.py            # FastAPI application
│   ├── requirements.txt   # Python deps
│   └── Dockerfile          # Backend container
├── frontend/
│   └── index.html         # Static frontend (HTML/CSS/JS)
└── backend.db             # SQLite database (in container)
```

## Development

```bash
# Edit frontend
vim frontend/index.html

# Rebuild and deploy
docker-compose build frontend
docker-compose up -d frontend
```

## Changelog

### 2026-04-27
- **Replaced Flet frontend** with pure HTML/CSS/JS
  - Flet + Pyodide had rendering issues in browser
  - New frontend is lightweight (~30KB vs ~3MB)
  - No framework dependencies
- Simplified nginx.conf
- Simplified Dockerfile.frontend
