"""
Beauty Shelf - Predefined product categories
"""

CARE_CATEGORIES = {
    "face_cream": {"name": "Крем для лица", "icon": "🧴"},
    "body_cream": {"name": "Крем для тела", "icon": "🧴"},
    "mask": {"name": "Маска", "icon": "💆"},
    "toner": {"name": "Тонер/Сыворотка", "icon": "💧"},
    "sunscreen": {"name": "Солнцезащитное", "icon": "☀️"},
    "cleanser": {"name": "Очищение", "icon": "🫧"},
    "patches": {"name": "Патчи", "icon": "👁️"},
    "basic_care": {"name": "Базовый уход", "icon": "✨"},
    "lip_care": {"name": "Уход для губ", "icon": "💋"},
    "eye_cream": {"name": "Крем для глаз", "icon": "👁️"},
    "serum": {"name": "Сыворотка", "icon": "💉"},
    "essence": {"name": "Эссенция", "icon": "💎"},
    "misting": {"name": "Мист", "icon": "💨"},
    "other_care": {"name": "Другое", "icon": "📦"},
}

DECORATIVE_CATEGORIES = {
    "foundation": {"name": "Тональное", "icon": "🎨"},
    "powder": {"name": "Пудра", "icon": "☁️"},
    "blush": {"name": "Румяна", "icon": "🌸"},
    "eyeshadow": {"name": "Тени для век", "icon": "🌈"},
    "mascara": {"name": "Тушь", "icon": "👁️"},
    "eyeliner": {"name": "Подводка/Кайла", "icon": "✏️"},
    "lipstick": {"name": "Помада/Блеск", "icon": "💄"},
    "brows": {"name": "Брови", "icon": "📐"},
    "palette": {"name": "Палетки", "icon": "🎭"},
    "perfume": {"name": "Парфюм", "icon": "🌸"},
    "base": {"name": "База под макияж", "icon": "🖌️"},
    "concealer": {"name": "Консилер", "icon": "🎯"},
    "highlighter": {"name": "Хайлайтер", "icon": "✨"},
    "bronzer": {"name": "Бронзер", "icon": "🏜️"},
    "primer": {"name": "Праймер", "icon": "💫"},
    "setting_spray": {"name": "Фиксатор", "icon": "💨"},
    "other_decorative": {"name": "Другое", "icon": "📦"},
}

# All categories combined
ALL_CATEGORIES = {
    "care": CARE_CATEGORIES,
    "decorative": DECORATIVE_CATEGORIES,
}

def get_category_name(category_key: str, product_type: str) -> str:
    """Get category display name."""
    categories = ALL_CATEGORIES.get(product_type, {})
    cat = categories.get(category_key, {})
    return cat.get("name", category_key)

def get_category_icon(category_key: str, product_type: str) -> str:
    """Get category emoji icon."""
    categories = ALL_CATEGORIES.get(product_type, {})
    cat = categories.get(category_key, {})
    return cat.get("icon", "📦")

def get_categories_for_type(product_type: str) -> dict:
    """Get all categories for a product type."""
    return ALL_CATEGORIES.get(product_type, {})

def get_all_category_keys() -> list[str]:
    """Get all category keys."""
    care_keys = list(CARE_CATEGORIES.keys())
    deco_keys = list(DECORATIVE_CATEGORIES.keys())
    return care_keys + deco_keys
