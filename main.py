"""
Beauty Shelf - Cosmetics Inventory Tracker
A minimal, beautiful app to track your cosmetic products and their expiry dates.
"""
import flet as ft

from database import init_database
from pages.home import HomePage


def main(page: ft.Page):
    """Application entry point."""
    # Initialize database
    init_database()
    
    # Theme and styling
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = ft.Theme(
        color_scheme_seed="#E8B4BC",
    )
    page.title = "Beauty Shelf"
    page.padding = 0
    page.spacing = 0
    page.window_width = 900
    page.window_height = 700
    page.window_min_width = 600
    page.window_min_height = 500
    
    # Set custom fonts via CSS-like approach
    page.fonts = {
        "Nunito": "https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap",
        "Inter": "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap",
    }
    
    # Build and show home page
    home_page = HomePage(page)
    page.add(home_page.build())
    page.update()
    
    # Load data after page is ready
    home_page.on_ready()


if __name__ == "__main__":
    ft.run(main)
