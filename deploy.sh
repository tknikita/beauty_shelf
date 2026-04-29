#!/bin/bash
# Beauty Shelf - Build and Deploy Script

set -e

echo "=== Beauty Shelf Build Script ==="

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Install Docker first."
    exit 1
fi

# Build frontend (Flutter Web)
echo "📦 Building frontend..."
cd beauty_shelf_app
flutter build web --release
cd ..
echo "✅ Frontend built"

# Build Docker
echo "🐳 Building Docker images..."
docker-compose build

echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "=== Services ==="
echo "Backend API: http://localhost:8000"
echo "Swagger Docs: http://localhost:8000/docs"
echo "Frontend: http://localhost:8080"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
