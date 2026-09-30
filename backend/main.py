"""
Beauty Shelf - Backend API (FastAPI + SQLite)
"""
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date
from contextlib import asynccontextmanager
import sqlite3
from pathlib import Path
import os
import uuid


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize the database when the application starts."""
    init_db()
    yield


app = FastAPI(title="Beauty Shelf API", version="0.1.0", lifespan=lifespan)

# CORS for web frontend.
# "*" must not be combined with credentials, so use an explicit allowlist.
# Override with ALLOWED_ORIGINS="https://app.example.com,https://admin.example.com".
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:8080,http://127.0.0.1:8080,http://localhost:3000",
    ).split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# DB path - support both local and Docker
DB_DIR = Path("/app/data") if os.path.exists("/app") else Path(__file__).parent
DB_PATH = DB_DIR / "beauty_shelf.db"

# Image storage
IMG_DIR = DB_DIR / "images"
IMG_DIR.mkdir(parents=True, exist_ok=True)
MAX_UPLOAD_BYTES = 5 * 1024 * 1024  # 5 MB
ALLOWED_IMAGE_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "webp"}

# External API URLs
OPEN_FOOD_FACTS_URL = "https://world.openfoodfacts.org/api/v2/product/{barcode}.json"
OPEN_BEAUTY_FACTS_URL = "https://world.openbeautyfacts.org/api/v2/product/{barcode}.json"


def get_db():
    """Get database connection."""
    DB_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Initialize database (called from the application lifespan)."""
    DB_DIR.mkdir(parents=True, exist_ok=True)
    conn = get_db()
    with conn:
        # Create products table
        conn.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                type TEXT NOT NULL CHECK(type IN ('care', 'decorative')),
                category TEXT NOT NULL,
                purpose TEXT,
                expiry_date DATE NOT NULL,
                is_opened INTEGER DEFAULT 0,
                opened_date DATE,
                expiry_days_after_open INTEGER DEFAULT 30,
                image_url TEXT,
                notification_days INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Migrate existing data if columns don't exist
        try:
            conn.execute("ALTER TABLE products ADD COLUMN is_opened INTEGER DEFAULT 0")
        except sqlite3.OperationalError:
            pass
        try:
            conn.execute("ALTER TABLE products ADD COLUMN opened_date DATE")
        except sqlite3.OperationalError:
            pass
        try:
            conn.execute("ALTER TABLE products ADD COLUMN expiry_days_after_open INTEGER DEFAULT 30")
        except sqlite3.OperationalError:
            pass
        try:
            conn.execute("ALTER TABLE products ADD COLUMN image_url TEXT")
        except sqlite3.OperationalError:
            pass
        try:
            conn.execute("ALTER TABLE products ADD COLUMN notification_days INTEGER")
        except sqlite3.OperationalError:
            pass
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
            )
        """)
        conn.execute("INSERT OR IGNORE INTO settings (key, value) VALUES ('notifications_enabled', 'true')")
        conn.execute("INSERT OR IGNORE INTO settings (key, value) VALUES ('notification_days', '7')")
    conn.close()


# Barcode lookup endpoint (proxy to avoid CORS)
@app.get("/api/barcode/{barcode}")
async def lookup_barcode(barcode: str):
    """Lookup a product by barcode.

    Beauty/cosmetics sources are queried first, then food as a fallback.
    """
    import httpx

    for url_template in (OPEN_BEAUTY_FACTS_URL, OPEN_FOOD_FACTS_URL):
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                response = await client.get(
                    url_template.format(barcode=barcode),
                    headers={"User-Agent": "BeautyShelf/1.0"},
                )
            if response.status_code == 200:
                data = response.json()
                if data.get("status") == 1:
                    return data.get("product", {})
        except Exception:
            continue

    return {}


# Pydantic models
class ProductCreate(BaseModel):
    name: str
    type: str
    category: str
    purpose: Optional[str] = None
    expiry_date: date
    is_opened: bool = False
    opened_date: Optional[date] = None
    expiry_days_after_open: int = 30
    image_url: Optional[str] = None
    notification_days: Optional[int] = None


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    category: Optional[str] = None
    purpose: Optional[str] = None
    expiry_date: Optional[date] = None
    is_opened: Optional[bool] = None
    opened_date: Optional[date] = None
    expiry_days_after_open: Optional[int] = None
    image_url: Optional[str] = None
    notification_days: Optional[int] = None


class Product(BaseModel):
    id: int
    name: str
    type: str
    category: str
    purpose: Optional[str]
    expiry_date: str
    is_opened: int
    opened_date: Optional[str]
    expiry_days_after_open: int
    image_url: Optional[str]
    notification_days: Optional[int]
    created_at: Optional[str]
    updated_at: Optional[str]

    model_config = ConfigDict(from_attributes=True)


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
        """INSERT INTO products (name, type, category, purpose, expiry_date, is_opened, opened_date, expiry_days_after_open, image_url, notification_days)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            product.name,
            product.type,
            product.category,
            product.purpose,
            product.expiry_date.isoformat(),
            1 if product.is_opened else 0,
            product.opened_date.isoformat() if product.opened_date else None,
            product.expiry_days_after_open,
            product.image_url,
            product.notification_days
        )
    )
    conn.commit()
    product_id = cursor.lastrowid
    cursor = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    new_product = dict(cursor.fetchone())
    conn.close()
    return new_product


@app.put("/api/products/{product_id}", response_model=Product)
def update_product(product_id: int, product: ProductUpdate):
    """Update an existing product.

    Only fields explicitly present in the request body are changed, so
    passing ``null`` for a nullable field (purpose, opened_date, image_url,
    notification_days) clears it.
    """
    conn = get_db()
    cursor = conn.execute("SELECT id FROM products WHERE id = ?", (product_id,))
    if not cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")

    # Only fields the client actually sent (explicit null counts as "sent").
    data = product.model_dump(exclude_unset=True)

    updates, values = [], []
    for field, value in data.items():
        if field == "is_opened":
            values.append(1 if value else 0)
        elif field in ("expiry_date", "opened_date"):
            values.append(value.isoformat() if value is not None else None)
        else:
            values.append(value)
        updates.append(f"{field} = ?")

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
    """Get products expiring within specified days, including already expired.
    Considers both original expiry_date and opened-date PAO."""
    conn = get_db()
    cursor = conn.execute("""
        SELECT * FROM products 
        WHERE expiry_date <= date('now', '+' || ? || ' days')
           OR (is_opened = 1 AND opened_date IS NOT NULL 
               AND date(opened_date, '+' || expiry_days_after_open || ' days') <= date('now', '+' || ? || ' days'))
        ORDER BY expiry_date ASC
    """, (days, days))
    products = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return products


@app.get("/api/health")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": "0.1.0"}


# Image endpoints
@app.post("/api/images/upload")
async def upload_image(file: UploadFile = File(...)):
    """Upload an image and return its URL."""
    # Validate by extension: multipart clients (Flutter web) may send
    # "application/octet-stream" as the content type.
    original_name = file.filename or ""
    ext = original_name.rsplit(".", 1)[-1].lower() if "." in original_name else ""
    if ext not in ALLOWED_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Allowed: " + ", ".join(sorted(ALLOWED_IMAGE_EXTENSIONS)),
        )

    contents = await file.read()
    if len(contents) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Max {MAX_UPLOAD_BYTES // (1024 * 1024)} MB.",
        )

    filename = f"{uuid.uuid4().hex}.{ext}"
    filepath = IMG_DIR / filename
    with open(filepath, "wb") as f:
        f.write(contents)

    return {"url": f"/api/images/{filename}"}


@app.get("/api/images/{filename}")
async def get_image(filename: str):
    """Serve uploaded images."""
    filepath = IMG_DIR / filename
    if not filepath.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    from fastapi.responses import FileResponse
    return FileResponse(filepath)
