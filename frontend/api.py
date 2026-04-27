"""
Beauty Shelf - API client for frontend
Works with web, mobile, desktop - talks to backend API
"""
import httpx
from datetime import date, datetime
from typing import Optional, List, Dict
import asyncio

# For web browser: use /api/ path (nginx proxy)
# For desktop/mobile: use http://localhost:8000
# We detect platform at import time
import flet as _flet

# Check if running in browser (Pyodide)
_IS_WEB = False
try:
    import js  # Pyodide
    _IS_WEB = True
except ImportError:
    pass

def _get_base_url():
    """Get the base URL for API requests."""
    if _IS_WEB:
        try:
            # In browser, get origin from window.location
            import js
            return str(js.window.location.origin)
        except Exception:
            # Fallback during module load
            return "/api"
    else:
        return "http://localhost:8000"

# Lazy base URL - only get when actually making a request
_BASE_URL = None

def _get_api_base():
    global _BASE_URL
    if _BASE_URL is None:
        _BASE_URL = _get_base_url()
    return _BASE_URL

def _fetch_post(url: str, data: dict) -> dict:
    """Use browser's fetch API for web."""
    import js
    
    async def do_fetch():
        try:
            body = js.JSON.stringify(data)
            response = await js.fetch(url, {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": body
            })
            text = await response.text()
            return js.JSON.parse(text) if text.strip() else {}
        except Exception as e:
            print(f"Fetch error: {e}")
            return {}
    
    return do_fetch()

def _fetch_put(url: str, data: dict) -> dict:
    """Use browser's fetch API for web."""
    import js
    
    async def do_fetch():
        try:
            body = js.JSON.stringify(data)
            response = await js.fetch(url, {
                "method": "PUT",
                "headers": {"Content-Type": "application/json"},
                "body": body
            })
            text = await response.text()
            return js.JSON.parse(text) if text.strip() else {}
        except Exception as e:
            print(f"Fetch error: {e}")
            return {}
    
    return do_fetch()

def _fetch_delete(url: str) -> dict:
    """Use browser's fetch API for web."""
    import js
    
    async def do_fetch():
        try:
            response = await js.fetch(url, {"method": "DELETE"})
            text = await response.text()
            return js.JSON.parse(text) if text.strip() else {}
        except Exception as e:
            print(f"Fetch error: {e}")
            return {}
    
    return do_fetch()


def set_backend_url(url: str):
    """Set the backend API URL."""
    global BACKEND_URL
    BACKEND_URL = url


def _get(url: str) -> dict | list:
    """GET request to backend."""
    full_url = f"{_get_api_base()}{url}"
    print(f"API GET: {full_url}")
    
    if _IS_WEB:
        import js
        
        async def fetch_data():
            try:
                response = await js.fetch(full_url, {"method": "GET"})
                if response.status == 200 or response.status == 201:
                    text = await response.text()
                    if text.strip():
                        # Convert JS object to Python dict
                        return js.JSON.parse(text).to_py()
                return [] if "products" in url else {}
            except Exception as e:
                print(f"Fetch error: {e}")
                return [] if "products" in url else {}
        
        return asyncio.run(fetch_data())
    else:
        try:
            response = httpx.get(full_url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"API error: {e}")
            return [] if "products" in url else {}


def _post(url: str, data: dict) -> dict:
    """POST request to backend."""
    full_url = f"{_get_api_base()}{url}"
    print(f"API POST: {full_url}")
    
    if _IS_WEB:
        import js
        
        async def post_data():
            try:
                body = js.JSON.stringify(data)
                response = await js.fetch(full_url, {
                    "method": "POST",
                    "headers": {"Content-Type": "application/json"},
                    "body": body
                })
                text = await response.text()
                if text.strip():
                    return js.JSON.parse(text).to_py()
                return {}
            except Exception as e:
                print(f"Fetch POST error: {e}")
                return {}
        
        return asyncio.run(post_data())
    else:
        try:
            response = httpx.post(full_url, json=data, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"API error: {e}")
            return {}


def _put(url: str, data: dict) -> dict:
    """PUT request to backend."""
    full_url = f"{_get_api_base()}{url}"
    
    if _IS_WEB:
        import js
        
        async def put_data():
            try:
                body = js.JSON.stringify(data)
                response = await js.fetch(full_url, {
                    "method": "PUT",
                    "headers": {"Content-Type": "application/json"},
                    "body": body
                })
                text = await response.text()
                if text.strip():
                    return js.JSON.parse(text).to_py()
                return {}
            except Exception as e:
                print(f"Fetch PUT error: {e}")
                return {}
        
        return asyncio.run(put_data())
    else:
        try:
            response = httpx.put(full_url, json=data, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"API error: {e}")
            return {}


def _delete(url: str) -> dict:
    """DELETE request to backend."""
    full_url = f"{_get_api_base()}{url}"
    
    if _IS_WEB:
        import js
        
        async def delete_data():
            try:
                response = await js.fetch(full_url, {"method": "DELETE"})
                text = await response.text()
                if text.strip():
                    return js.JSON.parse(text).to_py()
                return {}
            except Exception as e:
                print(f"Fetch DELETE error: {e}")
                return {}
        
        return asyncio.run(delete_data())
    else:
        try:
            response = httpx.delete(full_url, timeout=10)
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
    return _get("/products")


def get_products_by_type(product_type: str) -> List[dict]:
    """Get products by type."""
    return _get(f"/products?type={product_type}")


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
    result = _post("/products", data)
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
    _put(f"/products/{product_id}", data)


def delete_product(product_id: int) -> None:
    """Delete a product."""
    _delete(f"/products/{product_id}")


def search_products(query: str) -> List[dict]:
    """Search products."""
    return _get(f"/products/search/{query}")


# Settings
def get_setting(key: str) -> Optional[str]:
    """Get a setting."""
    result = _get(f"/settings/{key}")
    return result.get("value")


def set_setting(key: str, value: str) -> None:
    """Set a setting."""
    _put(f"/settings/{key}", {"value": value})


# Expiring products
def get_expiring_products(days: int = 7) -> List[dict]:
    """Get products expiring soon."""
    return _get(f"/expiring?days={days}")


def get_expired_products() -> List[dict]:
    """Get expired products."""
    return _get("/expired")
