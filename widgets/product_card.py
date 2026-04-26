"""
Beauty Shelf - Product card widget
"""
import flet as ft

from models import Product


def product_card(product: Product, on_edit, on_delete) -> ft.Card:
    """Single product card with styling."""
    
    # Colors based on expiry status
    status_colors = {
        "ok": "#8FC9A3",
        "warning": "#E8A87C",
        "critical": "#E8A87C",
        "expired": "#D9848C",
    }
    bg_colors = {
        "ok": "#F0F7F2",
        "warning": "#FDF5F0",
        "critical": "#FDF5F0",
        "expired": "#FDF0F2",
    }
    
    status = product.expiry_status
    status_color = status_colors[status]
    bg_color = bg_colors[status]
    
    # Expiry text
    if product.is_expired:
        expiry_text = f"Просрочено {-product.days_until_expiry} дн."
    else:
        expiry_text = f"⏱ {product.days_until_expiry} дн. до конца"
    
    # Format date
    date_str = product.expiry_date.strftime("%d.%m.%Y")
    
    return ft.Card(
        elevation=ft.BoxShadow(
            spread_radius=0,
            blur_radius=12,
            color="#00000014",
            offset=ft.Offset(0, 4),
        ),
        shape=ft.RoundedRectangleBorder(radius=16),
        color="#FFFFFF",
        content=ft.Container(
            padding=16,
            content=ft.Column(
                cross_axis_alignment=ft.CrossAxisAlignment.START,
                spacing=10,
                controls=[
                    # Header with category icon and title
                    ft.Row(
                        alignment=ft.MainAxisAlignment.START,
                        controls=[
                            ft.Container(
                                content=ft.Text(product.category_icon, size=24),
                                padding=8,
                                bgcolor=bg_color,
                                shape=ft.RoundedRectangleBorder(radius=12),
                            ),
                            ft.Container(width=8),
                            ft.Column(
                                controls=[
                                    ft.Text(
                                        value=product.name,
                                        size=16,
                                        weight=ft.FontWeight.W_600,
                                        color="#2D2D2D",
                                        max_lines=2,
                                        overflow=ft.TextOverflow.ELLIPSIS,
                                    ),
                                    ft.Text(
                                        value=f"{product.type_display} • {product.category_display}",
                                        size=12,
                                        color="#8A8A8A",
                                    ),
                                ],
                                expand=True,
                            ),
                        ],
                    ),
                    
                    # Purpose
                    ft.Container(
                        width=float("inf"),
                        padding=ft.padding.Padding(12, 8, 12, 8),
                        bgcolor="#F5E6E8",
                        border_radius=8,
                        content=ft.Text(
                            value=product.purpose if product.purpose else "Не указано",
                            size=13,
                            color="#8A8A8A" if not product.purpose else "#5A5A5A",
                            max_lines=2,
                            overflow=ft.TextOverflow.ELLIPSIS,
                            italic=not bool(product.purpose),
                        ),
                    ),
                    
                    # Expiry info
                    ft.Container(
                        content=ft.Column(
                            controls=[
                                ft.Row(
                                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                                    controls=[
                                        ft.Text(
                                            value=f"📅 {date_str}",
                                            size=13,
                                            color="#5A5A5A",
                                        ),
                                        ft.Container(
                                            content=ft.Text(
                                                value=expiry_text,
                                                size=12,
                                                color=status_color,
                                                weight=ft.FontWeight.W_500,
                                            ),
                                            padding=ft.padding.Padding(8, 4, 8, 4),
                                            bgcolor=bg_color,
                                            border_radius=8,
                                        ),
                                    ],
                                ),
                                ft.Container(height=6),
                                # Progress bar
                                ft.Container(
                                    content=ft.Row(
                                        controls=[
                                            ft.Container(
                                                expand=int(product.expiry_percentage),
                                                height=6,
                                                bgcolor=status_color,
                                                border_radius=3,
                                            ),
                                            ft.Container(
                                                expand=100 - int(product.expiry_percentage),
                                                height=6,
                                                bgcolor="#E8E8E8",
                                                border_radius=3,
                                            ) if product.expiry_percentage < 100 else ft.Container(),
                                        ],
                                    ),
                                    border_radius=3,
                                    clip=True,
                                ),
                            ],
                        ),
                    ),
                    
                    # Action buttons
                    ft.Row(
                        alignment=ft.MainAxisAlignment.END,
                        controls=[
                            ft.IconButton(
                                icon=ft.icons.Icons.EDIT,
                                icon_color="#8A8A8A",
                                icon_size=20,
                                tooltip="Редактировать",
                                on_click=on_edit,
                            ),
                            ft.IconButton(
                                icon=ft.icons.Icons.DELETE,
                                icon_color="#D9848C",
                                icon_size=20,
                                tooltip="Удалить",
                                on_click=on_delete,
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
