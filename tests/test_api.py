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
from datetime import date, timedelta

client = TestClient(app)


def _date(offset_days: int) -> str:
    """ISO date string relative to server-local today (negative = past).

    The backend compares against SQLite ``date('now', 'localtime')``, which
    matches Python's local ``date.today()``.
    """
    return (date.today() + timedelta(days=offset_days)).isoformat()


@pytest.fixture(autouse=True)
def test_db():
    """Use a temporary database and image directory for tests."""
    # Create temp file for test database
    with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
        temp_db = f.name

    # Monkey-patch the db path and image dir
    import backend.main as main_module
    import shutil
    original_path = main_module.DB_PATH
    original_img_dir = main_module.IMG_DIR
    temp_img_dir = tempfile.mkdtemp()
    main_module.DB_PATH = temp_db
    main_module.IMG_DIR = Path(temp_img_dir)

    # Re-init db
    init_db()

    yield temp_db

    # Cleanup
    main_module.DB_PATH = original_path
    main_module.IMG_DIR = original_img_dir
    try:
        os.unlink(temp_db)
    except Exception:
        pass
    shutil.rmtree(temp_img_dir, ignore_errors=True)


class TestImagesAPI:
    def test_upload_valid_image(self):
        """A valid image is stored and served back."""
        response = client.post(
            "/api/images/upload",
            files={"file": ("photo.png", b"\x89PNG\r\n\x1a\n fake-bytes", "image/png")},
        )
        assert response.status_code == 200
        url = response.json()["url"]
        assert url.startswith("/api/images/")

        get_resp = client.get(url)
        assert get_resp.status_code == 200

    def test_upload_rejects_invalid_extension(self):
        """Non-image extensions are rejected."""
        response = client.post(
            "/api/images/upload",
            files={"file": ("evil.exe", b"MZ", "application/octet-stream")},
        )
        assert response.status_code == 400


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

    def test_notification_days_round_trip(self):
        """notification_days is persisted and returned."""
        create_resp = client.post("/api/products", json={
            "name": "Крем",
            "type": "care",
            "category": "face_cream",
            "expiry_date": "2025-09-01",
            "notification_days": 7,
        })
        assert create_resp.status_code == 201
        product_id = create_resp.json()["id"]
        assert create_resp.json()["notification_days"] == 7

        update_resp = client.put(f"/api/products/{product_id}", json={
            "notification_days": 14,
        })
        assert update_resp.status_code == 200
        assert update_resp.json()["notification_days"] == 14

        # Explicit null disables the reminder.
        clear_resp = client.put(f"/api/products/{product_id}", json={
            "notification_days": None,
        })
        assert clear_resp.json()["notification_days"] is None

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


class TestPaoFields:
    def test_opened_fields_round_trip_and_clear(self):
        """Opened/PAO fields are stored and can be reset to null."""
        resp = client.post("/api/products", json={
            "name": "Крем PAO",
            "type": "care",
            "category": "face_cream",
            "expiry_date": _date(100),
            "is_opened": True,
            "opened_date": _date(-3),
            "expiry_days_after_open": 90,
        })
        assert resp.status_code == 201
        data = resp.json()
        product_id = data["id"]
        assert data["is_opened"] == 1
        assert data["opened_date"] == _date(-3)
        assert data["expiry_days_after_open"] == 90

        cleared = client.put(f"/api/products/{product_id}", json={
            "is_opened": False,
            "opened_date": None,
        }).json()
        assert cleared["is_opened"] == 0
        assert cleared["opened_date"] is None

    def test_opened_without_date_does_not_trigger_pao(self):
        """is_opened without opened_date must not use PAO for /expiring."""
        client.post("/api/products", json={
            "name": "Без даты",
            "type": "care",
            "category": "face_cream",
            "expiry_date": _date(200),
            "is_opened": True,
            "opened_date": None,
            "expiry_days_after_open": 5,
        })
        data = client.get("/api/expiring?days=7").json()
        assert all(p["name"] != "Без даты" for p in data)


class TestExpiringAPI:
    def _create(self, **overrides):
        payload = {
            "name": "P",
            "type": "care",
            "category": "face_cream",
            "expiry_date": _date(100),
        }
        payload.update(overrides)
        resp = client.post("/api/products", json=payload)
        assert resp.status_code == 201
        return resp.json()

    def test_includes_soon_and_excludes_far(self):
        self._create(name="Скоро", expiry_date=_date(3))
        self._create(name="Далеко", expiry_date=_date(200))

        names = [p["name"] for p in client.get("/api/expiring?days=7").json()]
        assert "Скоро" in names
        assert "Далеко" not in names

    def test_outside_window_is_excluded(self):
        self._create(name="Через3", expiry_date=_date(3))
        names = [p["name"] for p in client.get("/api/expiring?days=1").json()]
        assert "Через3" not in names

    def test_already_expired_is_included(self):
        self._create(name="Просрочен", expiry_date=_date(-5))
        names = [p["name"] for p in client.get("/api/expiring?days=0").json()]
        assert "Просрочен" in names

    def test_boundary_exactly_n_days_is_included(self):
        self._create(name="Ровно7", expiry_date=_date(7))
        names = [p["name"] for p in client.get("/api/expiring?days=7").json()]
        assert "Ровно7" in names

    def test_pao_triggers_expiring_even_when_printed_expiry_is_far(self):
        # Printed expiry +365d, but opened 2 days ago with a 5-day PAO.
        self._create(
            name="PAO",
            expiry_date=_date(365),
            is_opened=True,
            opened_date=_date(-2),
            expiry_days_after_open=5,
        )
        names7 = [p["name"] for p in client.get("/api/expiring?days=7").json()]
        names1 = [p["name"] for p in client.get("/api/expiring?days=1").json()]
        assert "PAO" in names7
        assert "PAO" not in names1

    def test_opened_respects_nearer_printed_expiry(self):
        """Per SPEC, the effective expiry is the earlier of the printed expiry
        and the PAO date, so a near printed expiry MUST trigger /expiring even
        when PAO is far."""
        self._create(
            name="ОткрытPAO",
            expiry_date=_date(3),
            is_opened=True,
            opened_date=_date(-1),
            expiry_days_after_open=300,
        )
        names = [p["name"] for p in client.get("/api/expiring?days=7").json()]
        assert "ОткрытPAO" in names

    def test_opened_not_expiring_when_both_limits_are_far(self):
        # Printed expiry +365d and PAO +299d -> the earlier limit is +299d.
        self._create(
            name="ОбаДалеко",
            expiry_date=_date(365),
            is_opened=True,
            opened_date=_date(-1),
            expiry_days_after_open=300,
        )
        names = [p["name"] for p in client.get("/api/expiring?days=7").json()]
        assert "ОбаДалеко" not in names

    def test_default_days_is_seven(self):
        self._create(name="Деф7", expiry_date=_date(5))
        self._create(name="Деф30", expiry_date=_date(20))
        names = [p["name"] for p in client.get("/api/expiring").json()]
        assert "Деф7" in names
        assert "Деф30" not in names
