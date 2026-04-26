"""
Beauty Shelf - Empty state widget
"""
import flet as ft


def empty_state(on_add_click) -> ft.Container:
    """Placeholder shown when no products exist."""
    return ft.Container(
        content=ft.Column(
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Text(
                    value="💄",
                    size=64,
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Container(height=16),
                ft.Text(
                    value="Ваша полка пуста",
                    size=24,
                    weight=ft.FontWeight.W_500,
                    color="#2D2D2D",
                ),
                ft.Container(height=8),
                ft.Text(
                    value="Добавьте первый продукт,\nчтобы начать отслеживать сроки годности",
                    size=14,
                    color="#8A8A8A",
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Container(height=24),
                ft.ElevatedButton(
                    content=ft.Row(
                        controls=[
                            ft.Text("+", size=18, weight=ft.FontWeight.BOLD),
                            ft.Text("Добавить продукт", size=14),
                        ],
                        spacing=4,
                        alignment=ft.MainAxisAlignment.CENTER,
                    ),
                    style=ft.ButtonStyle(
                        bgcolor="#E8B4BC",
                        color="#FFFFFF",
                        padding=ft.padding.Padding(16, 12, 16, 12),
                        shape=ft.RoundedRectangleBorder(radius=24),
                    ),
                    on_click=on_add_click,
                ),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        ),
        alignment=ft.alignment.Alignment(0, 0),
        expand=True,
    )
