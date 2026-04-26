"""
Beauty Shelf - API client for frontend
Works with web, mobile, desktop - talks to backend API
"""
import httpx
from datetime import date, datetime
from typing import Optional, List, Dict

# Backend URL - configurable
BACKEND_URL = "http://localhost:8000"


def set_backend_url(url: str):
    """Set the backend API URL."""
    global BACKEND_URL
    BACKEND_URL = url


def _get(url: str) -> dict | list:
    """GET request to backend."""
    try:
        response = httpx.get(f"{BACKEND_URL}{url}", timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"API error: {e}")
        return [] if "products" in url else {}


def _post(url: str, data: dict) -> dict:
    """POST request to backend."""
    try:
        response = httpx.post(f"{BACKEND_URL}{url}", json=data, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"API error: {e}")
        return {}


def _put(url: str, data: dict) -> dict:
    """PUT request to backend."""
    try:
        response = httpx.put(f"{BACKEND_URL}{url}", json=data, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"API error: {e}")
        return {}


def _delete(url: str) -> dict:
    """DELETE request to backend."""
    try:
        response = httpx.delete(f"{BACKEND_URL}{url}", timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"API error: {e}")
        return {}


# Initialize (no-op for API client)
def init_database() -> None:
    pass


# Product operations
def get_all_products() -> List[dict]:
    """Get all products."""
    return _get("/api/products")


def get_products_by_type(product_type: str) -> List[dict]:
    """Get products by type."""
    return _get(f"/api/products?type={product_type}")


def add_product(name: str, product_type: str, category: str, 
                purpose: Optional[str], expiry_date: date) -> int:
    """Add a new product."""
    data = {
        "name": name,
        "type": product_type,
        "category": category,
        "purpose": purpose,
        "expiry_date": expiry_date.isoformat() if hasattr(expiry_date, 'isoformat') else str(expiry_date)
    }
    result = _post("/api/products", data)
    return result.get("id", 0)


def update_product(product_id: int, name: str, product_type: str, 
                  category: str, purpose: Optional[str], expiry_date: date) -> None:
    """Update a product."""
    data = {
        "name": name,
        "type": product_type,
        "category": category,
        "purpose": purpose,
        "expiry_date": expiry_date.isoformat() if hasattr(expiry_date, 'isoformat') else str(expiry_date)
    }
    _put(f"/api/products/{product_id}", data)


def delete_product(product_id: int) -> None:
    """Delete a product."""
    _delete(f"/api/products/{product_id}")


def search_products(query: str) -> List[dict]:
    """Search products."""
    return _get(f"/api/products/search/{query}")


# Settings
def get_setting(key: str) -> Optional[str]:
    """Get a setting."""
    result = _get(f"/api/settings/{key}")
    return result.get("value")


def set_setting(key: str, value: str) -> None:
    """Set a setting."""
    _put(f"/api/settings/{key}", {"value": value})


# Expiring products
def get_expiring_products(days: int = 7) -> List[dict]:
    """Get products expiring soon."""
    return _get(f"/api/expiring?days={days}")


def get_expired_products() -> List[dict]:
    """Get expired products."""
    return _get("/api/expired")
