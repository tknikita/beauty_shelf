"""
Beauty Shelf - Backend API (FastAPI + SQLite)
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import sqlite3
from pathlib import Path
import os

app = FastAPI(title="Beauty Shelf API", version="0.1.0")

# CORS for web frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# DB path - support both local and Docker
DB_DIR = Path("/app/data") if os.path.exists("/app") else Path(__file__).parent
DB_PATH = DB_DIR / "beauty_shelf.db"


def get_db():
    """Get database connection."""
    DB_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


@app.on_event("startup")
def init_db():
    """Initialize database on startup."""
    DB_DIR.mkdir(parents=True, exist_ok=True)
    conn = get_db()
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
    conn.close()


# Pydantic models
class ProductCreate(BaseModel):
    name: str
    type: str
    category: str
    purpose: Optional[str] = None
    expiry_date: date


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    category: Optional[str] = None
    purpose: Optional[str] = None
    expiry_date: Optional[date] = None


class Product(BaseModel):
    id: int
    name: str
    type: str
    category: str
    purpose: Optional[str]
    expiry_date: str
    created_at: Optional[str]
    updated_at: Optional[str]

    class Config:
        from_attributes = True


# Products endpoints
@app.get("/api/products", response_model=list[Product])
def get_products(type: Optional[str] = None):
    """Get all products, optionally filtered by type."""
    conn = get_db()
    if type:
        cursor = conn.execute("SELECT * FROM products WHERE type = ? ORDER BY expiry_date ASC", (type,))
    else:
        cursor = conn.execute("SELECT * FROM products ORDER BY expiry_date ASC")
    products = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return products


@app.get("/api/products/{product_id}", response_model=Product)
def get_product(product_id: int):
    """Get a single product by ID."""
    conn = get_db()
    cursor = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    product = cursor.fetchone()
    conn.close()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return dict(product)


@app.post("/api/products", response_model=Product, status_code=201)
def create_product(product: ProductCreate):
    """Create a new product."""
    conn = get_db()
    cursor = conn.execute(
        """INSERT INTO products (name, type, category, purpose, expiry_date)
           VALUES (?, ?, ?, ?, ?)""",
        (product.name, product.type, product.category, product.purpose, product.expiry_date.isoformat())
    )
    conn.commit()
    product_id = cursor.lastrowid
    cursor = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    new_product = dict(cursor.fetchone())
    conn.close()
    return new_product


@app.put("/api/products/{product_id}", response_model=Product)
def update_product(product_id: int, product: ProductUpdate):
    """Update an existing product."""
    conn = get_db()
    cursor = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    if not cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")
    
    updates, values = [], []
    if product.name is not None:
        updates.append("name = ?")
        values.append(product.name)
    if product.type is not None:
        updates.append("type = ?")
        values.append(product.type)
    if product.category is not None:
        updates.append("category = ?")
        values.append(product.category)
    if product.purpose is not None:
        updates.append("purpose = ?")
        values.append(product.purpose)
    if product.expiry_date is not None:
        updates.append("expiry_date = ?")
        values.append(product.expiry_date.isoformat())
    
    updates.append("updated_at = CURRENT_TIMESTAMP")
    values.append(product_id)
    
    conn.execute(f"UPDATE products SET {', '.join(updates)} WHERE id = ?", values)
    conn.commit()
    cursor = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    updated = dict(cursor.fetchone())
    conn.close()
    return updated


@app.delete("/api/products/{product_id}")
def delete_product(product_id: int):
    """Delete a product."""
    conn = get_db()
    cursor = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    if not cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")
    conn.execute("DELETE FROM products WHERE id = ?", (product_id,))
    conn.commit()
    conn.close()
    return {"message": "Product deleted"}


@app.get("/api/products/search/{query}", response_model=list[Product])
def search_products(query: str):
    """Search products by name or purpose."""
    conn = get_db()
    cursor = conn.execute(
        "SELECT * FROM products WHERE name LIKE ? OR purpose LIKE ? ORDER BY expiry_date ASC",
        (f"%{query}%", f"%{query}%")
    )
    products = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return products


@app.get("/api/expiring")
def get_expiring(days: int = 7):
    """Get products expiring within specified days."""
    conn = get_db()
    cursor = conn.execute("""
        SELECT * FROM products 
        WHERE expiry_date <= date('now', '+' || ? || ' days')
        AND expiry_date >= date('now')
        ORDER BY expiry_date ASC
    """, (days,))
    products = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return products


@app.get("/api/health")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": "0.1.0"}
