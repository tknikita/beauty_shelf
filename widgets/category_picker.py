"""
Beauty Shelf - Category picker widget
"""
import flet as ft

from categories import CARE_CATEGORIES, DECORATIVE_CATEGORIES, ALL_CATEGORIES


def category_picker(
    product_type: str,
    selected_category: str = None,
    on_change=None,
) -> ft.Container:
    """
    Create a category picker based on product type.
    
    Args:
        product_type: 'care' or 'decorative'
        selected_category: Currently selected category key
        on_change: Callback when selection changes (category_key)
    """
    
    categories = ALL_CATEGORIES.get(product_type, CARE_CATEGORIES if product_type == "care" else DECORATIVE_CATEGORIES)
    selected = selected_category or list(categories.keys())[0]
    
    # Container for category chips
    chip_container = ft.Container()
    
    def make_chips():
        chips = []
        for key, info in categories.items():
            is_selected = key == selected
            
            chip = ft.Container(
                content=ft.Row(
                    controls=[
                        ft.Text(info["icon"], size=14),
                        ft.Text(info["name"], size=13),
                    ],
                    spacing=6,
                ),
                padding=ft.padding.Padding(12, 8, 12, 8),
                border_radius=12,
                border=ft.border.all(1.5, "#E8B4BC" if is_selected else "#E8E8E8"),
                bgcolor="#F5E6E8" if is_selected else "#FFFFFF",
                data=key,
            )
            
            def on_chip_click(e, k=key):
                # Update selection
                selected_val = k
                
                # Rebuild chips
                new_chips = []
                for ck, ci in categories.items():
                    is_s = ck == selected_val
                    nc = ft.Container(
                        content=ft.Row(
                            controls=[
                                ft.Text(ci["icon"], size=14),
                                ft.Text(ci["name"], size=13),
                            ],
                            spacing=6,
                        ),
                        padding=ft.padding.Padding(12, 8, 12, 8),
                        border_radius=12,
                        border=ft.border.all(1.5, "#E8B4BC" if is_s else "#E8E8E8"),
                        bgcolor="#F5E6E8" if is_s else "#FFFFFF",
                        data=ck,
                    )
                    
                    def handler(ev, key=ck):
                        on_chip_click(ev, key)
                    nc.on_click = handler
                    new_chips.append(nc)
                
                chip_container.content = ft.Row(
                    controls=new_chips,
                    wrap=True,
                    spacing=8,
                    run_spacing=8,
                )
                chip_container.update()
                
                if on_change:
                    on_change(selected_val)
            
            chip.on_click = on_chip_click
            chips.append(chip)
        
        return chips
    
    chip_container.content = ft.Row(
        controls=make_chips(),
        wrap=True,
        spacing=8,
        run_spacing=8,
    )
    
    return chip_container


def simple_category_dropdown(
    product_type: str,
    selected_category: str = None,
    on_change=None,
) -> ft.Dropdown:
    """Simple dropdown for category selection."""
    
    categories = ALL_CATEGORIES.get(product_type, CARE_CATEGORIES if product_type == "care" else DECORATIVE_CATEGORIES)
    selected = selected_category or list(categories.keys())[0]
    
    options = [
        ft.dropdown.Option(
            key=key,
            text=f"{info['icon']} {info['name']}",
        )
        for key, info in categories.items()
    ]
    
    dropdown = ft.Dropdown(
        label="Категория",
        options=options,
        value=selected,
        border_radius=12,
        border_color="#E8B4BC",
        focused_border_color="#D497A3",
        text_style=ft.TextStyle(size=14),
        on_change=lambda e: on_change(e.control.value) if on_change else None,
    )
    
    return dropdown
