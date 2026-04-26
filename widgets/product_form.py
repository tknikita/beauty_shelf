"""
Beauty Shelf - Product form modal
"""
import flet as ft
from datetime import date, timedelta

from models import Product
from categories import ALL_CATEGORIES, CARE_CATEGORIES, DECORATIVE_CATEGORIES


def product_form(
    page: ft.Page,
    product: Product | None,
    on_save,
    on_cancel,
) -> ft.Container:
    """Modal form for adding/editing products."""
    
    is_edit = product is not None
    title = "Редактировать продукт" if is_edit else "Добавить продукт"
    
    # Form fields
    name_field = ft.TextField(
        label="Название",
        hint_text="Введите название продукта",
        value=product.name if is_edit else "",
        autofocus=True,
        border_radius=12,
        border_color="#E8B4BC",
        focused_border_color="#D497A3",
        text_style=ft.TextStyle(size=14),
    )
    
    # Type selector
    selected_type = ft.Text(value=product.type if is_edit else "care", visible=False)
    
    # Category dropdown
    category_dropdown = ft.Dropdown(
        label="Категория",
        options=[],
        value=None,
        border_radius=12,
        border_color="#E8B4BC",
        focused_border_color="#D497A3",
        text_style=ft.TextStyle(size=14),
    )
    
    def update_categories(t):
        """Update category dropdown based on selected type."""
        cats = ALL_CATEGORIES.get(t, CARE_CATEGORIES if t == "care" else DECORATIVE_CATEGORIES)
        category_dropdown.options = [
            ft.dropdown.Option(
                key=key,
                text=f"{info['icon']} {info['name']}",
            )
            for key, info in cats.items()
        ]
        # Select first if no current selection
        if not category_dropdown.value or category_dropdown.value not in cats:
            category_dropdown.value = list(cats.keys())[0]
        category_dropdown.update()
    
    # Type selector UI
    type_care = ft.Container(
        content=ft.Text("🧴 Уходовая", size=14),
        padding=ft.padding.Padding(16, 12, 16, 12),
        border=ft.border.all(1, "#E8B4BC" if selected_type.value == "care" else "#E8E8E8"),
        border_radius=12,
        bgcolor="#F5E6E8" if selected_type.value == "care" else None,
        data="care",
    )
    
    type_deco = ft.Container(
        content=ft.Text("💄 Декоративная", size=14),
        padding=ft.padding.Padding(16, 12, 16, 12),
        border=ft.border.all(1, "#E8B4BC" if selected_type.value == "decorative" else "#E8E8E8"),
        border_radius=12,
        bgcolor="#F5E6E8" if selected_type.value == "decorative" else None,
        data="decorative",
    )
    
    def on_type_click(e, container):
        """Handle type selection."""
        new_type = container.data
        
        # Reset
        type_care.border_color = "#E8E8E8"
        type_care.bgcolor = None
        type_deco.border_color = "#E8E8E8"
        type_deco.bgcolor = None
        
        # Highlight selected
        container.border_color = "#E8B4BC"
        container.bgcolor = "#F5E6E8"
        selected_type.value = new_type
        
        type_care.update()
        type_deco.update()
        
        update_categories(new_type)
    
    type_care.on_click = lambda e: on_type_click(e, type_care)
    type_deco.on_click = lambda e: on_type_click(e, type_deco)
    
    purpose_field = ft.TextField(
        label="Для чего",
        hint_text="Увлажнение, питание, маскировка...",
        value=product.purpose if is_edit else "",
        multiline=True,
        max_lines=3,
        border_radius=12,
        border_color="#E8B4BC",
        focused_border_color="#D497A3",
        text_style=ft.TextStyle(size=14),
    )
    
    # Date picker
    date_picker = ft.DatePicker()
    
    # Selected date display
    initial_date = product.expiry_date if is_edit else date.today()
    date_display = ft.Text(
        value=f"Выбрать дату: {initial_date.strftime('%d.%m.%Y')}",
        size=14,
    )
    
    selected_date = ft.Text(value=initial_date.strftime("%d.%m.%Y"), visible=False)
    actual_date = ft.Text(value=initial_date.isoformat(), visible=False)
    
    date_btn = ft.ElevatedButton(
        content=ft.Row(
            controls=[
                ft.Text("📅 ", size=14),
                date_display,
            ],
            spacing=8,
        ),
        style=ft.ButtonStyle(
            bgcolor="#FFFFFF",
            color="#2D2D2D",
            padding=ft.padding.Padding(16, 12, 16, 12),
            shape=ft.RoundedRectangleBorder(radius=12),
            side=ft.BorderSide(1, "#E8E8E8"),
        ),
        on_click=lambda e: page.show_dialog(date_picker),
    )
    
    def on_date_change(e):
        if date_picker.value:
            date_str = date_picker.value.strftime("%d.%m.%Y")
            date_display.value = f"Выбрать дату: {date_str}"
            selected_date.value = date_str
            actual_date.value = date_picker.value.isoformat()
            date_btn.update()
    
    date_picker.on_change = on_date_change
    
    # Initialize categories
    init_type = product.type if is_edit else "care"
    init_cats = ALL_CATEGORIES.get(init_type, CARE_CATEGORIES)
    init_cat = product.category if is_edit else list(init_cats.keys())[0]
    
    category_dropdown.options = [
        ft.dropdown.Option(
            key=key,
            text=f"{info['icon']} {info['name']}",
        )
        for key, info in init_cats.items()
    ]
    category_dropdown.value = init_cat
    
    def validate_and_save(e):
        """Validate and save."""
        errors = []
        
        if not name_field.value.strip():
            errors.append("Введите название")
            name_field.border_color = "#D9848C"
            name_field.update()
        
        if errors:
            return
        
        # Parse date
        chosen_date = date.today()
        if actual_date.value:
            try:
                chosen_date = date.fromisoformat(actual_date.value)
            except:
                chosen_date = date.today()
        
        on_save(
            name_field.value.strip(),
            selected_type.value,
            category_dropdown.value,
            purpose_field.value.strip() or None,
            chosen_date,
        )
    
    return ft.Container(
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            horizontal_alignment=ft.CrossAxisAlignment.STRETCH,
            controls=[
                # Header
                ft.Container(
                    content=ft.Row(
                        alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                        controls=[
                            ft.Text(
                                value=title,
                                size=20,
                                weight=ft.FontWeight.W_600,
                                color="#2D2D2D",
                            ),
                            ft.IconButton(
                                icon=ft.icons.Icons.CLOSE,
                                icon_color="#8A8A8A",
                                on_click=on_cancel,
                            ),
                        ],
                    ),
                    padding=ft.padding.Padding(0, 0, 0, 20),
                ),
                
                # Name field
                name_field,
                ft.Container(height=16),
                
                # Type selector
                ft.Text("Тип продукта", size=14, color="#5A5A5A", weight=ft.FontWeight.W_500),
                ft.Container(height=8),
                ft.Row(
                    controls=[type_care, ft.Container(width=12), type_deco],
                ),
                selected_type,
                ft.Container(height=16),
                
                # Category dropdown
                category_dropdown,
                ft.Container(height=16),
                
                # Purpose field
                purpose_field,
                ft.Container(height=16),
                
                # Date picker
                ft.Text("Срок годности", size=14, color="#5A5A5A", weight=ft.FontWeight.W_500),
                ft.Container(height=8),
                ft.Row(
                    controls=[date_btn, date_picker],
                ),
                selected_date,
                actual_date,
                ft.Container(height=24),
                
                # Buttons
                ft.Row(
                    alignment=ft.MainAxisAlignment.END,
                    controls=[
                        ft.TextButton(
                            content=ft.Text("Отмена", size=14),
                            style=ft.ButtonStyle(color="#8A8A8A"),
                            on_click=on_cancel,
                        ),
                        ft.Container(width=12),
                        ft.ElevatedButton(
                            content=ft.Text("Сохранить", size=14, weight=ft.FontWeight.W_500),
                            style=ft.ButtonStyle(
                                bgcolor="#E8B4BC",
                                color="#FFFFFF",
                                padding=ft.padding.Padding(24, 12, 24, 12),
                                shape=ft.RoundedRectangleBorder(radius=12),
                            ),
                            on_click=validate_and_save,
                        ),
                    ],
                ),
            ],
        ),
        padding=24,
        width=400,
        bgcolor="#FFFFFF",
        border_radius=20,
        shadow=ft.BoxShadow(
            spread_radius=0,
            blur_radius=20,
            color="#00000020",
            offset=ft.Offset(0, 8),
        ),
    )


def confirmation_dialog(
    title: str,
    message: str,
    on_confirm,
    on_cancel,
) -> ft.Container:
    """Confirmation dialog for destructive actions."""
    return ft.Container(
        content=ft.Column(
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Text("⚠️", size=48),
                ft.Container(height=16),
                ft.Text(
                    value=title,
                    size=18,
                    weight=ft.FontWeight.W_600,
                    color="#2D2D2D",
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Container(height=8),
                ft.Text(
                    value=message,
                    size=14,
                    color="#8A8A8A",
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Container(height=24),
                ft.Row(
                    alignment=ft.MainAxisAlignment.CENTER,
                    controls=[
                        ft.TextButton(
                            content=ft.Text("Отмена", size=14),
                            style=ft.ButtonStyle(color="#8A8A8A"),
                            on_click=on_cancel,
                        ),
                        ft.Container(width=16),
                        ft.ElevatedButton(
                            content=ft.Text("Удалить", size=14, weight=ft.FontWeight.W_500),
                            style=ft.ButtonStyle(
                                bgcolor="#D9848C",
                                color="#FFFFFF",
                                padding=ft.padding.Padding(20, 10, 20, 10),
                                shape=ft.RoundedRectangleBorder(radius=12),
                            ),
                            on_click=on_confirm,
                        ),
                    ],
                ),
            ],
        ),
        padding=32,
        width=320,
        bgcolor="#FFFFFF",
        border_radius=20,
        shadow=ft.BoxShadow(
            spread_radius=0,
            blur_radius=20,
            color="#00000020",
            offset=ft.Offset(0, 8),
        ),
    )
