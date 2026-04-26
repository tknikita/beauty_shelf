"""
Beauty Shelf - Product card widget
"""
import flet as ft

from models import Product


def product_card(product: Product, on_edit, on_delete) -> ft.Container:
    """Single product card with styling - responsive width."""
    
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
        expiry_text = f"{product.days_until_expiry} дн."
    
    # Format date
    date_str = product.expiry_date.strftime("%d.%m.%Y")
    
    return ft.Container(
        width=200,  # Base width, will be adjusted by Row
        content=ft.Card(
            elevation=ft.BoxShadow(
                spread_radius=0,
                blur_radius=8,
                color="#00000010",
                offset=ft.Offset(0, 2),
            ),
            shape=ft.RoundedRectangleBorder(radius=14),
            color="#FFFFFF",
            content=ft.Container(
                padding=12,
                content=ft.Column(
                    cross_axis_alignment=ft.CrossAxisAlignment.START,
                    spacing=8,
                    controls=[
                        # Header with category icon and title
                        ft.Row(
                            alignment=ft.MainAxisAlignment.START,
                            vertical_alignment=ft.CrossAxisAlignment.CENTER,
                            controls=[
                                ft.Container(
                                    content=ft.Text(product.category_icon, size=20),
                                    padding=6,
                                    bgcolor=bg_color,
                                    shape=ft.RoundedRectangleBorder(radius=10),
                                ),
                                ft.Container(width=6),
                                ft.Column(
                                    controls=[
                                        ft.Text(
                                            value=product.name,
                                            size=14,
                                            weight=ft.FontWeight.W_600,
                                            color="#2D2D2D",
                                            max_lines=2,
                                            overflow=ft.TextOverflow.ELLIPSIS,
                                        ),
                                        ft.Text(
                                            value=product.category_display,
                                            size=11,
                                            color="#8A8A8A",
                                        ),
                                    ],
                                    expand=True,
                                ),
                            ],
                        ),
                        
                        # Purpose
                        ft.Container(
                            padding=ft.padding.Padding(8, 6, 8, 6),
                            bgcolor="#F5F5F5",
                            border_radius=6,
                            content=ft.Text(
                                value=product.purpose if product.purpose else "Не указано",
                                size=12,
                                color="#666666" if not product.purpose else "#444444",
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
                                                size=11,
                                                color="#666666",
                                            ),
                                            ft.Container(
                                                content=ft.Text(
                                                    value=expiry_text,
                                                    size=10,
                                                    color=status_color,
                                                    weight=ft.FontWeight.W_600,
                                                ),
                                                padding=ft.padding.Padding(6, 3, 6, 3),
                                                bgcolor=bg_color,
                                                border_radius=6,
                                            ),
                                        ],
                                    ),
                                    ft.Container(height=4),
                                    # Progress bar
                                    ft.Container(
                                        height=4,
                                        border_radius=2,
                                        bgcolor="#E8E8E8",
                                        clip_behavior="hardEdge",
                                        content=ft.Row(
                                            controls=[
                                                ft.Container(
                                                    width=max(2, int(product.expiry_percentage * 1.7)),
                                                    height=4,
                                                    bgcolor=status_color,
                                                    border_radius=2,
                                                ),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        
                        # Action buttons
                        ft.Row(
                            alignment=ft.MainAxisAlignment.END,
                            controls=[
                                ft.Container(expand=True),
                                ft.IconButton(
                                    icon=ft.icons.Icons.EDIT,
                                    icon_color="#888888",
                                    icon_size=18,
                                    tooltip="Редактировать",
                                    on_click=on_edit,
                                ),
                                ft.IconButton(
                                    icon=ft.icons.Icons.DELETE,
                                    icon_color="#D9848C",
                                    icon_size=18,
                                    tooltip="Удалить",
                                    on_click=on_delete,
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    )
