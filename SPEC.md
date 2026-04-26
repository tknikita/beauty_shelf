# Beauty Shelf - Technical Specification

## Overview

Cross-platform cosmetics inventory tracker with web frontend and FastAPI backend.

## Architecture

```
┌──────────────────┐     HTTP/WS      ┌─────────────────┐
│  Nginx (Port 80) │ ◄──────────────► │  FastAPI (8000) │
│  + Static Files  │                  │  + SQLite        │
└──────────────────┘                  └─────────────────┘
         │
         ├── Serves: index.html, main.dart.mjs, main.dart.wasm
         ├── Proxy: /api/* → backend:8000
         └── Proxy: /ws → backend:8000 (WebSocket)
```

## Components

### Frontend (Flet Web)
- Built with Flet 0.84+ (Pyodide/WASM)
- Deploy directory: `frontend_build/`
- Entry points:
  - `main.dart.mjs` - ES Module (WASM target)
  - `main.dart.js` - Legacy JS (CanvasKit)

### Backend (FastAPI)
- Port: 8000
- Database: SQLite (`beauty_shelf.db`)
- Endpoints:
  - `GET /api/products` - List all
  - `POST /api/products` - Create
  - `GET/PUT/DELETE /api/products/{id}` - CRUD
  - `GET /api/expiring?days=7` - Expiring items
  - `GET /api/health` - Health check

### Database Schema
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT CHECK(type IN ('care', 'decorative')),
    category TEXT NOT NULL,
    purpose TEXT,
    expiry_date DATE NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Docker Configuration

### Services
1. **backend** - Python 3.12 + FastAPI
2. **frontend** - Nginx Alpine + Static build

### Nginx Configuration (nginx.conf)
Critical settings for Flet web app:

```nginx
# MIME types for ES Modules and WASM
location ~ \.mjs$ {
    types { }
    default_type "application/javascript";
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}

location ~ \.wasm$ {
    types { }
    default_type "application/wasm";
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}

# WebSocket proxy for Flet
location /ws {
    proxy_pass http://backend:8000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

### Known Issues Fixed
1. **MIME Type octet-stream**: ES Modules (.mjs) and WASM require explicit MIME type configuration
2. **Browser Cache**: Use `Cache-Control: no-cache` during development to avoid cached wrong MIME types
3. **Location Order**: MIME type handlers must be defined BEFORE `location /` block

## Product Categories

### Care (Уходовая)
- Face Care, Body Care, Hair Care
- Eye Care, Lip Care, Nail Care
- Sun Protection, Masks, Serums
- Tonics, Creams, Exfoliators

### Decorative (Декоративная)
- Face, Eyes, Lips, Nails
- Cheeks, Brows, Setting

## Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Rebuild after changes
docker-compose build --no-cache frontend
docker-compose restart frontend
```

## Production Notes

- HTTPS required for service worker registration
- For production: add SSL termination to nginx
- WebSocket connection needed for Flet real-time features
