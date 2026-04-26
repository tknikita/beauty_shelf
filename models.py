"""
Beauty Shelf - Data models
"""
from dataclasses import dataclass
from datetime import date, datetime
from typing import Optional

from categories import get_category_name, get_category_icon


@dataclass
class Product:
    """Cosmetic product model."""
    id: int
    name: str
    type: str  # 'care' or 'decorative'
    category: str  # sub-category key
    purpose: Optional[str]
    expiry_date: date
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    @property
    def type_display(self) -> str:
        """Human-readable type name."""
        return "Уходовая" if self.type == "care" else "Декоративная"
    
    @property
    def type_icon(self) -> str:
        """Emoji icon for product type."""
        return "🧴" if self.type == "care" else "💄"
    
    @property
    def category_display(self) -> str:
        """Human-readable category name."""
        return get_category_name(self.category, self.type)
    
    @property
    def category_icon(self) -> str:
        """Emoji icon for category."""
        return get_category_icon(self.category, self.type)
    
    @property
    def days_until_expiry(self) -> int:
        """Days remaining until expiry (negative if expired)."""
        return (self.expiry_date - date.today()).days
    
    @property
    def is_expired(self) -> bool:
        """Check if product is expired."""
        return self.days_until_expiry < 0
    
    @property
    def expiry_status(self) -> str:
        """Status: 'expired', 'critical', 'warning', 'ok'."""
        days = self.days_until_expiry
        if days < 0:
            return "expired"
        elif days < 30:
            return "critical"
        elif days < 60:
            return "warning"
        return "ok"
    
    @property
    def expiry_percentage(self) -> float:
        """Percentage of time remaining (100 = full, 0 = expired)."""
        total_days = 365
        days_left = max(0, self.days_until_expiry)
        return min(100, (days_left / total_days) * 100)
    
    def __post_init__(self):
        """Convert date strings to date objects."""
        if isinstance(self.expiry_date, str):
            self.expiry_date = date.fromisoformat(self.expiry_date)
        if self.created_at and isinstance(self.created_at, str):
            self.created_at = datetime.fromisoformat(self.created_at)
        if self.updated_at and isinstance(self.updated_at, str):
            self.updated_at = datetime.fromisoformat(self.updated_at)
