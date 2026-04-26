"""
Beauty Shelf - Main page with product grid
"""
import flet as ft

from database import get_all_products, get_products_by_type, search_products
from models import Product
from widgets.empty_state import empty_state
from widgets.product_card import product_card
from widgets.product_form import product_form, confirmation_dialog
from notifications import get_notification_service


class HomePage:
    """Main application page."""
    
    def __init__(self, page: ft.Page):
        self.page = page
        self.products: list[Product] = []
        self.current_filter = "all"
        self.search_query = ""
        self.main_container = None
        self.settings_visible = False
        
        # UI Components
        self.grid_view = ft.GridView(
            expand=True,
            runs_count=3 if self.page.width > 600 else 2,
            max_extent=280,
            spacing=16,
            run_spacing=16,
            padding=16,
        )
        
        self.filter_chips = ft.Row(
            spacing=8,
            controls=[
                self._make_filter_chip("Все", "all"),
                self._make_filter_chip("🧴 Уходовая", "care"),
                self._make_filter_chip("💄 Декоративная", "decorative"),
            ],
        )
        
        self.search_field = ft.TextField(
            hint_text="Поиск...",
            prefix_icon=ft.icons.Icons.SEARCH,
            visible=False,
            border_radius=24,
            border_color="#E8B4BC",
            focused_border_color="#D497A3",
            on_change=self._on_search,
            width=200,
        )
        
        self.search_visible = False
        
        # Check notifications on init
        self._check_notifications()
    
    def _check_notifications(self):
        """Check for expiring products and show notification."""
        try:
            service = get_notification_service()
            expiring = service.get_expiring_products()
            expired = service.get_expired_products()
            
            messages = []
            if expired:
                messages.append(f"⚠️ Просрочено: {', '.join(p['name'] for p in expired[:3])}")
            if expiring:
                urgent = [p for p in expiring if p['days_left'] <= 7]
                if urgent:
                    messages.append(f"📅 Скоро истекает: {', '.join(p['name'] for p in urgent[:3])}")
            
            # Show in-app notification if there are expiring products
            if messages and hasattr(self.page, 'show_snack_bar'):
                self.page.show_snack_bar(
                    ft.SnackBar(
                        content=ft.Text("\n".join(messages)),
                        bgcolor="#E8A87C" if expired else "#F5E6E8",
                        duration=5,
                        action=ft.TextButton(
                            content=ft.Text("Подробнее", color="#2D2D2D"),
                            on_click=None,
                        ),
                    )
                )
        except Exception as e:
            print(f"Notification check failed: {e}")
    
    def _make_filter_chip(self, label: str, value: str) -> ft.Container:
        """Create filter chip button."""
        is_active = self.current_filter == value
        
        chip = ft.Container(
            content=ft.Text(label, size=14),
            padding=ft.padding.Padding(16, 8, 16, 8),
            border_radius=20,
            border=ft.border.all(1, "#E8B4BC" if is_active else "#E8E8E8"),
            bgcolor="#E8B4BC" if is_active else "#FFFFFF",
            data=value,
        )
        
        def on_click(e):
            self.current_filter = value
            self._update_filter_chips()
            self.load_products()
        
        chip.on_click = on_click
        return chip
    
    def _update_filter_chips(self):
        """Update filter chip styles."""
        for chip in self.filter_chips.controls:
            is_active = chip.data == self.current_filter
            chip.border = ft.border.all(1, "#E8B4BC" if is_active else "#E8E8E8")
            chip.bgcolor = "#E8B4BC" if is_active else "#FFFFFF"
        self.filter_chips.update()
    
    def _on_search(self, e):
        """Handle search input."""
        self.search_query = e.control.value
        self.load_products()
    
    def toggle_search(self, e):
        """Toggle search field visibility."""
        self.search_visible = not self.search_visible
        self.search_field.visible = self.search_visible
        if self.search_visible:
            self.search_field.focus()
        self.page.update()
    
    def load_products(self):
        """Load products from database."""
        if self.search_query:
            data = search_products(self.search_query)
        elif self.current_filter == "all":
            data = get_all_products()
        else:
            data = get_products_by_type(self.current_filter)
        
        self.products = [Product(**row) for row in data]
        self._render_grid()
    
    def _render_grid(self):
        """Render product grid."""
        self.grid_view.controls.clear()
        
        if not self.products:
            self.grid_view.controls.append(
                ft.Container(
                    col={"xs": 12, "sm": 12, "md": 12, "lg": 12, "xl": 12},
                    content=ft.Column(
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        controls=[
                            ft.Text("💄", size=48),
                            ft.Container(height=8),
                            ft.Text(
                                value="Ничего не найдено",
                                size=16,
                                color="#8A8A8A",
                            ),
                        ],
                    ),
alignment=ft.alignment.Alignment(0, 0),
                    padding=48,
                )
            )
        else:
            for product in self.products:
                self.grid_view.controls.append(
                    product_card(
                        product,
                        on_edit=lambda e, p=product: self._open_edit_modal(p),
                        on_delete=lambda e, p=product: self._confirm_delete(p),
                    )
                )
        
        self.grid_view.update()
        self.page.update()
    
    def _open_add_modal(self, e=None):
        """Open modal to add new product."""
        modal_content = product_form(
            page=self.page,
            product=None,
            on_save=self._save_new_product,
            on_cancel=self._close_modal,
        )
        self._show_modal(modal_content)
    
    def _open_edit_modal(self, product: Product):
        """Open modal to edit product."""
        modal_content = product_form(
            page=self.page,
            product=product,
            on_save=lambda name, ptype, cat, purpose, date: self._save_edit(product.id, name, ptype, cat, purpose, date),
            on_cancel=self._close_modal,
        )
        self._show_modal(modal_content)
    
    def _save_new_product(self, name, ptype, cat, purpose, expiry_date):
        """Save new product to database."""
        from database import add_product
        add_product(name, ptype, cat, purpose, expiry_date)
        self._close_modal()
        self.load_products()
    
    def _save_edit(self, product_id, name, ptype, cat, purpose, expiry_date):
        """Save edited product."""
        from database import update_product
        update_product(product_id, name, ptype, cat, purpose, expiry_date)
        self._close_modal()
        self.load_products()
    
    def _confirm_delete(self, product: Product):
        """Show confirmation dialog."""
        dialog = confirmation_dialog(
            title="Удалить продукт?",
            message=f'"{product.name}" будет удалён безвозвратно.',
            on_confirm=lambda e: self._delete_product(product.id),
            on_cancel=self._close_modal,
        )
        self._show_modal(dialog)
    
    def _delete_product(self, product_id: int):
        """Delete product from database."""
        from database import delete_product
        delete_product(product_id)
        self._close_modal()
        self.load_products()
    
    def _show_modal(self, content: ft.Container):
        """Show modal overlay."""
        modal = ft.Container(
            content=ft.Container(
                content=content,
                alignment=ft.alignment.Alignment(0, 0),
            ),
            alignment=ft.alignment.Alignment(0, 0),
            bgcolor="#00000080",
            expand=True,
            on_click=lambda e: self._close_modal(),
        )
        self.page.overlay.append(modal)
        self.page.update()
    
    def _close_modal(self, e=None):
        """Close modal overlay."""
        if self.page.overlay:
            self.page.overlay.clear()
        self.page.update()
    
    def _open_settings(self, e=None):
        """Open settings page."""
        from pages.settings import settings_page
        self.settings_visible = True
        
        def on_back(e):
            self.settings_visible = False
            self.main_container.content = self._build_main_content()
            self.main_container.update()
        
        self.main_container.content = settings_page(self.page, on_back)
        self.main_container.update()
    
    def _build_main_content(self) -> ft.Column:
        """Build main page content."""
        return ft.Column(
            expand=True,
            controls=[
                # Header
                ft.Container(
                    content=ft.Row(
                        alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                        controls=[
                            ft.Row(
                                controls=[
                                    ft.Text("💄", size=28),
                                    ft.Text(
                                        value="Beauty Shelf",
                                        size=24,
                                        weight=ft.FontWeight.W_600,
                                        color="#2D2D2D",
                                    ),
                                ],
                                spacing=8,
                            ),
                            ft.Row(
                                controls=[
                                    ft.IconButton(
                                        icon=ft.icons.Icons.SEARCH,
                                        icon_color="#8A8A8A",
                                        tooltip="Поиск",
                                        on_click=self.toggle_search,
                                    ),
                                    ft.IconButton(
                                        icon=ft.icons.Icons.SETTINGS,
                                        icon_color="#8A8A8A",
                                        tooltip="Настройки",
                                        on_click=self._open_settings,
                                    ),
                                    self.search_field,
                                    ft.ElevatedButton(
                                        content=ft.Row(
                                            controls=[
                                                ft.Text("+", size=18, weight=ft.FontWeight.BOLD),
                                                ft.Text("Добавить", size=14),
                                            ],
                                            spacing=4,
                                        ),
                                        style=ft.ButtonStyle(
                                            bgcolor="#E8B4BC",
                                            color="#FFFFFF",
                                            padding=ft.padding.Padding(16, 10, 16, 10),
                                            shape=ft.RoundedRectangleBorder(radius=20),
                                        ),
                                        on_click=self._open_add_modal,
                                    ),
                                ],
                                spacing=4,
                            ),
                        ],
                    ),
                    padding=ft.padding.Padding(16, 16, 16, 8),
                    bgcolor="#FFFFFF",
                    shadow=ft.BoxShadow(
                        spread_radius=0,
                        blur_radius=8,
                        color="#00000008",
                        offset=ft.Offset(0, 2),
                    ),
                ),
                
                # Filter chips
                ft.Container(
                    content=self.filter_chips,
                    padding=ft.padding.Padding(16, 12, 16, 0),
                    bgcolor="#FDF9FA",
                ),
                
                # Product grid
                ft.Container(
                    content=self.grid_view,
                    expand=True,
                    bgcolor="#FDF9FA",
                ),
            ],
        )
    
    def build(self) -> ft.Column:
        """Build main page layout."""
        self.main_container = ft.Container(
            content=self._build_main_content(),
            expand=True,
        )
        return self.main_container
    
    def on_ready(self):
        """Called after page is ready."""
        self.load_products()
