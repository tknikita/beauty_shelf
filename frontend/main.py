"""
Beauty Shelf - Frontend (Flet)
"""
import flet as ft
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from api import get_all_products, get_products_by_type, search_products, add_product, update_product, delete_product
from categories import CARE_CATEGORIES, DECORATIVE_CATEGORIES, get_category_name, get_category_icon


class Product:
    def __init__(self, data: dict):
        self.id = data.get("id")
        self.name = data.get("name", "")
        self.type = data.get("type", "care")
        self.category = data.get("category", "basic_care")
        self.purpose = data.get("purpose")
        self.expiry_date = data.get("expiry_date", "")
        self.created_at = data.get("created_at")
    
    @property
    def type_display(self):
        return "Уходовая" if self.type == "care" else "Декоративная"
    
    @property
    def category_display(self):
        return get_category_name(self.category, self.type)
    
    @property
    def category_icon(self):
        return get_category_icon(self.category, self.type)
    
    @property
    def days_left(self) -> int:
        from datetime import date
        if not self.expiry_date:
            return 999
        try:
            expiry = date.fromisoformat(self.expiry_date)
            return (expiry - date.today()).days
        except:
            return 999
    
    @property
    def status(self):
        d = self.days_left
        if d < 0: return "expired"
        if d < 30: return "critical"
        if d < 60: return "warning"
        return "ok"


class App:
    def __init__(self, page: ft.Page):
        self.page = page
        self.products = []
        self.filter = "all"
        self.search = ""
        
        self.content_col = ft.Column(scroll=ft.ScrollMode.AUTO, expand=True)
        
        self.page.add(self._build_ui())
        self.load()
    
    def _build_ui(self):
        return ft.Column(
            expand=True,
            controls=[
                # Header
                ft.Container(
                    content=ft.Column(
                        controls=[
                            ft.Row(
                                alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                                controls=[
                                    ft.Row([ft.Text("💄", size=24), ft.Text("Beauty Shelf", size=20, weight=ft.FontWeight.W_600)]),
                                    ft.Row([
                                        ft.IconButton(icon=ft.icons.Icons.SEARCH, icon_size=22, on_click=self.toggle_search),
                                        ft.Container(
                                            content=ft.Text("+", size=20, weight=ft.FontWeight.BOLD),
                                            bgcolor="#E8B4BC", width=36, height=36, border_radius=18,
                                            alignment=ft.alignment.Alignment(0, 0), on_click=self.add_product
                                        ),
                                    ]),
                                ],
                            ),
                            ft.Container(
                                content=ft.TextField(hint_text="Поиск...", prefix_icon=ft.icons.Icons.SEARCH, 
                                                    on_submit=self.do_search, border_radius=20, text_size=14),
                                padding=ft.padding.Padding(0, 8, 0, 0), visible=False
                            ),
                        ],
                    ),
                    padding=12, bgcolor="#FFFFFF",
                ),
                # Filters
                ft.Container(
                    content=ft.Row(
                        controls=[
                            self._chip("Все", "all"),
                            self._chip("🧴", "care"),
                            self._chip("💄", "decorative"),
                        ],
                        spacing=8,
                    ),
                    padding=ft.padding.Padding(12, 8, 12, 8), bgcolor="#F5F5F5",
                ),
                # Content
                ft.Container(content=self.content_col, expand=True, bgcolor="#FDF9FA"),
            ],
        )
    
    def _chip(self, label, value):
        active = self.filter == value
        return ft.Container(
            content=ft.Text(label, size=13),
            padding=ft.padding.Padding(12, 6, 12, 6),
            border_radius=16,
            border=ft.border.all(1, "#E8B4BC" if active else "#E8E8E8"),
            bgcolor="#E8B4BC" if active else "#FFFFFF",
            on_click=lambda e: self.set_filter(value),
        )
    
    def toggle_search(self, e):
        pass  # Simplified
    
    def do_search(self, e):
        self.search = e.control.value
        self.load()
    
    def set_filter(self, value):
        self.filter = value
        self.load()
    
    def load(self):
        try:
            if self.search:
                data = search_products(self.search)
            elif self.filter == "all":
                data = get_all_products()
            else:
                data = get_products_by_type(self.filter)
            self.products = [Product(p) for p in data]
        except Exception as e:
            print(f"Load error: {e}")
            self.products = []
        self.render()
    
    def render(self):
        self.content_col.controls.clear()
        
        if not self.products:
            self.content_col.controls.append(
                ft.Container(
                    content=ft.Column(
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        controls=[
                            ft.Text("💄", size=56),
                            ft.Text("Полка пуста", size=18, weight=ft.FontWeight.W_500),
                            ft.Text("Нажмите + чтобы добавить", size=14, color="#8A8A8A"),
                        ],
                    ),
                    alignment=ft.alignment.Alignment(0, 0), padding=60,
                )
            )
        else:
            # Grid layout
            cols = 2 if self.page.width and self.page.width < 600 else 3
            
            for i in range(0, len(self.products), cols):
                row_items = []
                for j in range(cols):
                    if i + j < len(self.products):
                        row_items.append(self._card(self.products[i + j]))
                
                if row_items:
                    self.content_col.controls.append(
                        ft.Container(
                            content=ft.Row(row_items, spacing=10, run_spacing=10),
                            padding=ft.padding.Padding(8, 8, 8, 8),
                        )
                    )
        
        self.page.update()
    
    def _card(self, product: Product):
        colors = {"ok": "#8FC9A3", "warning": "#E8A87C", "critical": "#E8A87C", "expired": "#D9848C"}
        bg_colors = {"ok": "#F0F7F2", "warning": "#FDF5F0", "critical": "#FDF5F0", "expired": "#FDF0F2"}
        
        s = product.status
        col = colors[s]
        bg = bg_colors[s]
        
        days_txt = f"Просрочено {-product.days_left} дн." if product.days_left < 0 else f"{product.days_left} дн."
        
        return ft.Container(
            width=180,
            content=ft.Card(
                elevation=ft.BoxShadow(spread_radius=0, blur_radius=6, color="#00000010"),
                shape=ft.RoundedRectangleBorder(radius=12),
                content=ft.Container(
                    padding=10,
                    content=ft.Column(
                        spacing=6,
                        controls=[
                            ft.Row(
                                controls=[
                                    ft.Container(
                                        content=ft.Text(product.category_icon, size=18),
                                        padding=6, bgcolor=bg, shape=ft.RoundedRectangleBorder(radius=8),
                                    ),
                                    ft.Column(
                                        controls=[
                                            ft.Text(product.name, size=14, weight=ft.FontWeight.W_600, max_lines=2),
                                            ft.Text(product.category_display, size=11, color="#8A8A8A"),
                                        ], expand=True,
                                    ),
                                ], alignment=ft.MainAxisAlignment.START,
                            ),
                            ft.Container(
                                content=ft.Text(product.purpose or "—", size=12, color="#666666", max_lines=2),
                                padding=6, bgcolor="#F5F5F5", border_radius=6,
                            ),
                            ft.Row(
                                controls=[
                                    ft.Text(f"📅 {product.expiry_date}", size=11, color="#666666"),
                                    ft.Container(
                                        content=ft.Text(days_txt, size=10, color=col, weight=ft.FontWeight.W_600),
                                        padding=ft.padding.Padding(4, 2, 4, 2), bgcolor=bg, border_radius=4,
                                    ),
                                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                            ),
                            ft.Row(
                                controls=[
                                    ft.Container(expand=True),
                                    ft.IconButton(icon=ft.icons.Icons.EDIT, icon_size=16, icon_color="#888888",
                                                 on_click=lambda e, p=product: self.edit_product(p)),
                                    ft.IconButton(icon=ft.icons.Icons.DELETE, icon_size=16, icon_color="#D9848C",
                                                 on_click=lambda e, p=product: self.delete_product(p)),
                                ], alignment=ft.MainAxisAlignment.END,
                            ),
                        ],
                    ),
                ),
            ),
        )
    
    def add_product(self, e=None):
        self._show_form(None)
    
    def edit_product(self, product: Product):
        self._show_form(product)
    
    def delete_product(self, product: Product):
        def confirm(e):
            try:
                delete_product(product.id)
                self.page.dialog.open = False
                self.page.update()
                self.load()
            except Exception as ex:
                print(f"Delete error: {ex}")
        
        def cancel(e):
            self.page.dialog.open = False
            self.page.update()
        
        self.page.dialog = ft.AlertDialog(
            modal=True,
            title=ft.Text("Удалить?"),
            content=ft.Text(f'"{product.name}" будет удалён.'),
            actions=[
                ft.TextButton("Отмена", on_click=cancel),
                ft.TextButton("Удалить", on_click=confirm),
            ],
        )
        self.page.dialog.open = True
        self.page.update()
    
    def _show_form(self, product: Product):
        is_edit = product is not None
        title = "Редактировать" if is_edit else "Добавить продукт"
        
        name = ft.TextField(label="Название", value=product.name if is_edit else "", autofocus=True, border_radius=10)
        purpose = ft.TextField(label="Для чего", value=product.purpose or "" if is_edit else "", border_radius=10)
        date_field = ft.TextField(
            label="Срок (YYYY-MM-DD)", 
            value=product.expiry_date.split("T")[0] if is_edit and product.expiry_date else "",
            border_radius=10
        )
        
        selected_type = ft.Text(value=product.type if is_edit else "care")
        
        cats = CARE_CATEGORIES if selected_type.value == "care" else DECORATIVE_CATEGORIES
        cat_dropdown = ft.Dropdown(
            label="Категория",
            value=product.category if is_edit else list(cats.keys())[0],
            options=[ft.dropdown.Option(key=k, text=f"{v['icon']} {v['name']}") for k, v in cats.items()],
            border_radius=10,
        )
        
        def save(e):
            if not name.value or not date_field.value:
                return
            from datetime import date
            try:
                exp_date = date.fromisoformat(date_field.value)
            except:
                return
            
            try:
                if is_edit:
                    update_product(product.id, name.value, selected_type.value, cat_dropdown.value, 
                                 purpose.value or None, exp_date)
                else:
                    add_product(name.value, selected_type.value, cat_dropdown.value, purpose.value or None, exp_date)
                self.page.dialog.open = False
                self.page.update()
                self.load()
            except Exception as ex:
                print(f"Save error: {ex}")
        
        def cancel(e):
            self.page.dialog.open = False
            self.page.update()
        
        def select_type(t):
            selected_type.value = t
            cats = CARE_CATEGORIES if t == "care" else DECORATIVE_CATEGORIES
            cat_dropdown.options = [ft.dropdown.Option(key=k, text=f"{v['icon']} {v['name']}") for k, v in cats.items()]
            cat_dropdown.value = list(cats.keys())[0]
            type_row.controls[0].border = ft.border.all(1, "#E8B4BC" if t == "care" else "#E8E8E8")
            type_row.controls[1].border = ft.border.all(1, "#E8B4BC" if t == "decorative" else "#E8E8E8")
            self.page.dialog.update()
        
        type_row = ft.Row([
            ft.Container(
                content=ft.Text("🧴", size=16),
                padding=10, border_radius=8,
                border=ft.border.all(1, "#E8B4BC" if selected_type.value == "care" else "#E8E8E8"),
                on_click=lambda e: select_type("care"),
            ),
            ft.Container(
                content=ft.Text("💄", size=16),
                padding=10, border_radius=8,
                border=ft.border.all(1, "#E8B4BC" if selected_type.value == "decorative" else "#E8E8E8"),
                on_click=lambda e: select_type("decorative"),
            ),
        ])
        
        self.page.dialog = ft.AlertDialog(
            modal=True,
            title=ft.Text(title),
            content=ft.Column(spacing=12, controls=[name, type_row, cat_dropdown, purpose, date_field]),
            actions=[
                ft.TextButton("Отмена", on_click=cancel),
                ft.TextButton("Сохранить", on_click=save),
            ],
        )
        self.page.dialog.open = True
        self.page.update()


def main(page: ft.Page):
    page.title = "Beauty Shelf"
    page.theme_mode = ft.ThemeMode.LIGHT
    App(page)


if __name__ == "__main__":
    ft.run(main)
