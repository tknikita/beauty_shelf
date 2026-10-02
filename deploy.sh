#!/bin/bash
# Beauty Shelf - Build and Deploy Script

set -e

echo "=== Beauty Shelf Build Script ==="

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Install Docker first."
    exit 1
fi

# Build mobile app (Flutter Android)
echo "📦 Building Android APK..."
if command -v flutter &> /dev/null; then
    (cd beauty_shelf_app && flutter build apk --release)
    echo "✅ Android APK built"
else
    echo "⚠️  Flutter not found. Skipping APK build."
fi

# Build backend Docker image
echo "🐳 Building backend image..."
docker-compose build

echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "=== Services ==="
echo "Backend API: http://localhost:8000"
echo "Swagger Docs: http://localhost:8000/docs"
echo "Mobile APK: beauty_shelf_app/build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
