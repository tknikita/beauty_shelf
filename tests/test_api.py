"""
Backend API Tests
"""
import pytest
import sys
import os
from pathlib import Path

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from fastapi.testclient import TestClient
from backend.main import app, get_db, init_db
import sqlite3
import tempfile

client = TestClient(app)


@pytest.fixture(autouse=True)
def test_db():
    """Use a temporary database for tests."""
    # Create temp file for test database
    with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
        temp_db = f.name
    
    # Monkey-patch the db path
    import backend.main as main_module
    original_path = main_module.DB_PATH
    main_module.DB_PATH = temp_db
    
    # Re-init db
    init_db()
    
    yield temp_db
    
    # Cleanup
    main_module.DB_PATH = original_path
    try:
        os.unlink(temp_db)
    except:
        pass


class TestHealthEndpoint:
    def test_health(self):
        """Test health check endpoint."""
        response = client.get("/api/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"


class TestProductsAPI:
    def test_create_product(self):
        """Test creating a product."""
        response = client.post("/api/products", json={
            "name": "Тестовый крем",
            "type": "care",
            "category": "face_cream",
            "purpose": "Увлажнение",
            "expiry_date": "2025-12-01"
        })
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Тестовый крем"
        assert data["type"] == "care"
        assert data["category"] == "face_cream"
        assert "id" in data
    
    def test_get_products(self):
        """Test getting all products."""
        # Create a product first
        client.post("/api/products", json={
            "name": "Помада",
            "type": "decorative",
            "category": "lipstick",
            "purpose": "Для губ",
            "expiry_date": "2025-06-01"
        })
        
        response = client.get("/api/products")
        assert response.status_code == 200
        assert isinstance(response.json(), list)
    
    def test_get_products_by_type(self):
        """Test filtering products by type."""
        client.post("/api/products", json={
            "name": "Крем",
            "type": "care",
            "category": "face_cream",
            "expiry_date": "2025-01-01"
        })
        
        response = client.get("/api/products?type=care")
        assert response.status_code == 200
        products = response.json()
        assert all(p["type"] == "care" for p in products)
    
    def test_get_product_by_id(self):
        """Test getting a single product."""
        # Create
        create_resp = client.post("/api/products", json={
            "name": "Маска",
            "type": "care",
            "category": "mask",
            "expiry_date": "2025-03-01"
        })
        product_id = create_resp.json()["id"]
        
        # Get
        response = client.get(f"/api/products/{product_id}")
        assert response.status_code == 200
        assert response.json()["name"] == "Маска"
    
    def test_update_product(self):
        """Test updating a product."""
        # Create
        create_resp = client.post("/api/products", json={
            "name": "Пудра",
            "type": "decorative",
            "category": "powder",
            "expiry_date": "2025-04-01"
        })
        product_id = create_resp.json()["id"]
        
        # Update
        response = client.put(f"/api/products/{product_id}", json={
            "name": "Пудра новая"
        })
        assert response.status_code == 200
        assert response.json()["name"] == "Пудра новая"
    
    def test_delete_product(self):
        """Test deleting a product."""
        # Create
        create_resp = client.post("/api/products", json={
            "name": "Удалить",
            "type": "care",
            "category": "basic_care",
            "expiry_date": "2025-05-01"
        })
        product_id = create_resp.json()["id"]
        
        # Delete
        response = client.delete(f"/api/products/{product_id}")
        assert response.status_code == 200
        
        # Verify deleted
        get_resp = client.get(f"/api/products/{product_id}")
        assert get_resp.status_code == 404
    
    def test_search_products(self):
        """Test searching products."""
        client.post("/api/products", json={
            "name": "Сыворотка с витамином C",
            "type": "care",
            "category": "serum",
            "expiry_date": "2025-07-01"
        })
        
        response = client.get("/api/products/search/витамин")
        assert response.status_code == 200
        products = response.json()
        assert len(products) >= 1
        assert "витамин" in products[0]["name"].lower()
    
    def test_get_nonexistent_product(self):
        """Test getting a non-existent product."""
        response = client.get("/api/products/99999")
        assert response.status_code == 404

    def test_update_clears_nullable_fields(self):
        """Explicitly sending null must clear nullable fields."""
        create_resp = client.post("/api/products", json={
            "name": "Сыворотка",
            "type": "care",
            "category": "serum",
            "purpose": "Увлажнение",
            "image_url": "/api/images/x.jpg",
            "expiry_date": "2025-08-01",
        })
        product_id = create_resp.json()["id"]

        response = client.put(f"/api/products/{product_id}", json={
            "purpose": None,
            "image_url": None,
        })
        assert response.status_code == 200
        data = response.json()
        assert data["purpose"] is None
        assert data["image_url"] is None
        # Untouched fields must remain intact.
        assert data["name"] == "Сыворотка"
