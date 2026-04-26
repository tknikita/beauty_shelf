"""
Beauty Shelf - Tracker for cosmetics inventory
Database layer with SQLite
"""
import sqlite3
from datetime import date, datetime
from pathlib import Path
from typing import Optional

DB_PATH = Path(__file__).parent / "cosmetics.db"


def get_connection() -> sqlite3.Connection:
    """Get database connection with row factory."""
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_database() -> None:
    """Initialize database schema."""
    with get_connection() as conn:
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
        
        # Settings table for app preferences
        conn.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
            )
        """)
        
        # Set default settings if not exist
        conn.execute("""
            INSERT OR IGNORE INTO settings (key, value) VALUES ('notifications_enabled', 'true')
        """)
        conn.execute("""
            INSERT OR IGNORE INTO settings (key, value) VALUES ('notification_days', '7')
        """)
        conn.execute("""
            INSERT OR IGNORE INTO settings (key, value) VALUES ('last_notification_date', '')
        """)
        
        conn.commit()


def get_all_products() -> list[dict]:
    """Get all products sorted by expiry date."""
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT * FROM products ORDER BY expiry_date ASC"
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def get_products_by_type(product_type: str) -> list[dict]:
    """Get products filtered by type."""
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT * FROM products WHERE type = ? ORDER BY expiry_date ASC",
            (product_type,)
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def get_products_by_category(category: str) -> list[dict]:
    """Get products filtered by category."""
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT * FROM products WHERE category = ? ORDER BY expiry_date ASC",
            (category,)
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def add_product(name: str, product_type: str, category: str, purpose: Optional[str],
                expiry_date: date) -> int:
    """Add new product, return its ID."""
    with get_connection() as conn:
        cursor = conn.execute(
            """INSERT INTO products (name, type, category, purpose, expiry_date)
               VALUES (?, ?, ?, ?, ?)""",
            (name, product_type, category, purpose, expiry_date.isoformat())
        )
        conn.commit()
        return cursor.lastrowid


def update_product(product_id: int, name: str, product_type: str, category: str,
                   purpose: Optional[str], expiry_date: date) -> None:
    """Update existing product."""
    with get_connection() as conn:
        conn.execute(
            """UPDATE products 
               SET name = ?, type = ?, category = ?, purpose = ?, expiry_date = ?,
                   updated_at = CURRENT_TIMESTAMP
               WHERE id = ?""",
            (name, product_type, category, purpose, expiry_date.isoformat(), product_id)
        )
        conn.commit()


def delete_product(product_id: int) -> None:
    """Delete product by ID."""
    with get_connection() as conn:
        conn.execute("DELETE FROM products WHERE id = ?", (product_id,))
        conn.commit()


def search_products(query: str) -> list[dict]:
    """Search products by name or purpose."""
    with get_connection() as conn:
        cursor = conn.execute(
            """SELECT * FROM products 
               WHERE name LIKE ? OR purpose LIKE ?
               ORDER BY expiry_date ASC""",
            (f"%{query}%", f"%{query}%")
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def get_setting(key: str) -> Optional[str]:
    """Get a setting value."""
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT value FROM settings WHERE key = ?",
            (key,)
        )
        row = cursor.fetchone()
        return row["value"] if row else None


def set_setting(key: str, value: str) -> None:
    """Set a setting value."""
    with get_connection() as conn:
        conn.execute(
            """INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)""",
            (key, value)
        )
        conn.commit()
