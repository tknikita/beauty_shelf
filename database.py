"""
Beauty Shelf - Tracker for cosmetics inventory
Database layer - supports both SQLite (desktop) and JSON (web)
"""
import json
import os
from datetime import date, datetime
from pathlib import Path
from typing import Optional

# DB path
DB_PATH = Path(__file__).parent / "cosmetics.db"
JSON_PATH = Path(__file__).parent / "cosmetics.json"

# Check if we're in web (Pyodide)
IS_WEB = __import__("sys").modules.get("pyodide", False) is not None


def get_connection():
    """Get database connection - SQLite for desktop, None for web."""
    if IS_WEB:
        return None
    import sqlite3
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_database() -> None:
    """Initialize database."""
    if IS_WEB:
        # Initialize JSON file for web
        if not JSON_PATH.exists():
            save_json_data({"products": [], "settings": {}})
        return
    
    # SQLite for desktop
    conn = get_connection()
    with conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                type TEXT NOT NULL CHECK(type IN ('care', 'decorative')),
                category TEXT NOT NULL,
                purpose TEXT,
                expiry_date DATE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
            )
        """)
        
        conn.execute("INSERT OR IGNORE INTO settings (key, value) VALUES ('notifications_enabled', 'true')")
        conn.execute("INSERT OR IGNORE INTO settings (key, value) VALUES ('notification_days', '7')")
        conn.execute("INSERT OR IGNORE INTO settings (key, value) VALUES ('last_notification_date', '')")
        conn.commit()


# JSON helpers for web
def load_json_data() -> dict:
    """Load data from JSON file."""
    if JSON_PATH.exists():
        with open(JSON_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"products": [], "settings": {}}


def save_json_data(data: dict) -> None:
    """Save data to JSON file."""
    with open(JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2, default=str)


# Product operations
def get_all_products() -> list[dict]:
    """Get all products sorted by expiry date."""
    if IS_WEB:
        data = load_json_data()
        products = data.get("products", [])
        # Sort by expiry_date
        products.sort(key=lambda x: x.get("expiry_date", ""))
        return products
    
    conn = get_connection()
    with conn:
        cursor = conn.execute("SELECT * FROM products ORDER BY expiry_date ASC")
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def get_products_by_type(product_type: str) -> list[dict]:
    """Get products filtered by type."""
    if IS_WEB:
        products = [p for p in get_all_products() if p.get("type") == product_type]
        products.sort(key=lambda x: x.get("expiry_date", ""))
        return products
    
    conn = get_connection()
    with conn:
        cursor = conn.execute(
            "SELECT * FROM products WHERE type = ? ORDER BY expiry_date ASC",
            (product_type,)
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def add_product(name: str, product_type: str, category: str, purpose: Optional[str],
                expiry_date: date) -> int:
    """Add new product, return its ID."""
    if IS_WEB:
        data = load_json_data()
        products = data.get("products", [])
        
        # Generate ID
        max_id = max([p.get("id", 0) for p in products], default=0)
        new_id = max_id + 1
        
        product = {
            "id": new_id,
            "name": name,
            "type": product_type,
            "category": category,
            "purpose": purpose,
            "expiry_date": expiry_date.isoformat() if hasattr(expiry_date, 'isoformat') else str(expiry_date),
        }
        products.append(product)
        data["products"] = products
        save_json_data(data)
        return new_id
    
    conn = get_connection()
    with conn:
        cursor = conn.execute(
            """INSERT INTO products (name, type, category, purpose, expiry_date)
               VALUES (?, ?, ?, ?, ?)""",
            (name, product_type, category, purpose, expiry_date.isoformat() if hasattr(expiry_date, 'isoformat') else str(expiry_date))
        )
        conn.commit()
        return cursor.lastrowid


def update_product(product_id: int, name: str, product_type: str, category: str,
                   purpose: Optional[str], expiry_date: date) -> None:
    """Update existing product."""
    if IS_WEB:
        data = load_json_data()
        products = data.get("products", [])
        for p in products:
            if p.get("id") == product_id:
                p["name"] = name
                p["type"] = product_type
                p["category"] = category
                p["purpose"] = purpose
                p["expiry_date"] = expiry_date.isoformat() if hasattr(expiry_date, 'isoformat') else str(expiry_date)
                break
        data["products"] = products
        save_json_data(data)
        return
    
    conn = get_connection()
    with conn:
        conn.execute(
            """UPDATE products 
               SET name = ?, type = ?, category = ?, purpose = ?, expiry_date = ?,
                   updated_at = CURRENT_TIMESTAMP
               WHERE id = ?""",
            (name, product_type, category, purpose, 
             expiry_date.isoformat() if hasattr(expiry_date, 'isoformat') else str(expiry_date),
             product_id)
        )
        conn.commit()


def delete_product(product_id: int) -> None:
    """Delete product by ID."""
    if IS_WEB:
        data = load_json_data()
        products = data.get("products", [])
        products = [p for p in products if p.get("id") != product_id]
        data["products"] = products
        save_json_data(data)
        return
    
    conn = get_connection()
    with conn:
        conn.execute("DELETE FROM products WHERE id = ?", (product_id,))
        conn.commit()


def search_products(query: str) -> list[dict]:
    """Search products by name or purpose."""
    if IS_WEB:
        query_lower = query.lower()
        products = [p for p in get_all_products() 
                   if query_lower in p.get("name", "").lower() 
                   or query_lower in p.get("purpose", "").lower()]
        return products
    
    conn = get_connection()
    with conn:
        cursor = conn.execute(
            """SELECT * FROM products 
               WHERE name LIKE ? OR purpose LIKE ?
               ORDER BY expiry_date ASC""",
            (f"%{query}%", f"%{query}%")
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


# Settings operations
def get_setting(key: str) -> Optional[str]:
    """Get a setting value."""
    if IS_WEB:
        data = load_json_data()
        settings = data.get("settings", {})
        return settings.get(key)
    
    conn = get_connection()
    with conn:
        cursor = conn.execute(
            "SELECT value FROM settings WHERE key = ?",
            (key,)
        )
        row = cursor.fetchone()
        return row["value"] if row else None


def set_setting(key: str, value: str) -> None:
    """Set a setting value."""
    if IS_WEB:
        data = load_json_data()
        data["settings"][key] = value
        save_json_data(data)
        return
    
    conn = get_connection()
    with conn:
        conn.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
            (key, value)
        )
        conn.commit()
