"""
Beauty Shelf - Settings page
"""
import flet as ft

from notifications import get_notification_service, NotificationConfig
from database import get_setting, set_setting


def settings_page(page: ft.Page, on_back) -> ft.Container:
    """Settings page for app configuration."""
    
    # Load current settings
    service = get_notification_service()
    config = service.config
    
    notifications_enabled = ft.Switch(
        value=config.enabled,
        label="Уведомления о сроке годности",
        active_color="#E8B4BC",
    )
    
    days_options = [
        "3 дня",
        "5 дней", 
        "7 дней",
        "14 дней",
        "30 дней",
    ]
    days_map = {3: "3 дня", 5: "5 дней", 7: "7 дней", 14: "14 дней", 30: "30 дней"}
    
    days_dropdown = ft.Dropdown(
        label="Уведомлять за",
        value=str(config.days_before),
        options=[
            ft.dropdown.Option(key=str(k), text=v) 
            for k, v in days_map.items()
        ],
        border_radius=12,
        border_color="#E8B4BC",
        text_style=ft.TextStyle(size=14),
    )
    
    def save_settings(e):
        """Save notification settings."""
        enabled = notifications_enabled.value
        days = int(days_dropdown.value)
        
        config.enabled = enabled
        config.days_before = days
        service.config = config
        service.save_config()
        
        # Show confirmation
        page.show_snack_bar(
            ft.SnackBar(
                content=ft.Text("Настройки сохранены ✓"),
                bgcolor="#8FC9A3",
                duration=2,
            )
        )
    
    return ft.Container(
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            controls=[
                # Header
                ft.Container(
                    content=ft.Row(
                        alignment=ft.MainAxisAlignment.START,
                        controls=[
                            ft.IconButton(
                                icon=ft.icons.Icons.ARROW_BACK,
                                icon_color="#2D2D2D",
                                on_click=on_back,
                            ),
                            ft.Text(
                                value="Настройки",
                                size=22,
                                weight=ft.FontWeight.W_600,
                                color="#2D2D2D",
                            ),
                        ],
                        spacing=8,
                    ),
                    padding=ft.padding.Padding(16, 16, 16, 8),
                ),
                
                # Notifications Section
                ft.Container(
                    content=ft.Column(
                        controls=[
                            ft.Text(
                                value="🔔 Уведомления",
                                size=18,
                                weight=ft.FontWeight.W_600,
                                color="#2D2D2D",
                            ),
                            ft.Container(height=16),
                            
                            # Enable toggle
                            ft.Container(
                                content=ft.Row(
                                    controls=[
                                        ft.Column(
                                            controls=[
                                                ft.Text(
                                                    value="Включить уведомления",
                                                    size=15,
                                                    color="#2D2D2D",
                                                ),
                                                ft.Text(
                                                    value="Получать напоминания о продуктах с истекающим сроком",
                                                    size=13,
                                                    color="#8A8A8A",
                                                ),
                                            ],
                                            expand=True,
                                        ),
                                        notifications_enabled,
                                    ],
                                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                                ),
                                padding=16,
                                bgcolor="#FFFFFF",
                                border_radius=12,
                                border=ft.border.all(1, "#E8E8E8"),
                            ),
                            
                            ft.Container(height=12),
                            
                            # Days dropdown
                            ft.Container(
                                content=days_dropdown,
                                padding=16,
                                bgcolor="#FFFFFF",
                                border_radius=12,
                                border=ft.border.all(1, "#E8E8E8"),
                            ),
                            
                            ft.Container(height=24),
                            
                            # Save button
                            ft.ElevatedButton(
                                content=ft.Text("Сохранить", size=14, weight=ft.FontWeight.W_500),
                                style=ft.ButtonStyle(
                                    bgcolor="#E8B4BC",
                                    color="#FFFFFF",
                                    padding=ft.padding.Padding(24, 12, 24, 12),
                                    shape=ft.RoundedRectangleBorder(radius=12),
                                ),
                                on_click=save_settings,
                            ),
                        ],
                    ),
                    padding=16,
                ),
                
                # Info Section
                ft.Container(height=24),
                ft.Container(
                    content=ft.Column(
                        controls=[
                            ft.Text(
                                value="ℹ️ О приложении",
                                size=18,
                                weight=ft.FontWeight.W_600,
                                color="#2D2D2D",
                            ),
                            ft.Container(height=12),
                            ft.Text(
                                value="Beauty Shelf — ваш личный трекер косметики.\nПомогает отслеживать сроки годности иnever забыть о любимых продуктах.",
                                size=14,
                                color="#8A8A8A",
                            ),
                            ft.Container(height=8),
                            ft.Text(
                                value="Версия 1.1",
                                size=12,
                                color="#B8B8B8",
                            ),
                        ],
                    ),
                    padding=16,
                ),
            ],
        ),
        padding=ft.padding.Padding(0, 0, 0, 16),
    )
