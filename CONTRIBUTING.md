# Contributing to Beauty Shelf

## 🚀 Quick Start

```bash
# Clone and setup
cd beauty_shelf
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run desktop app
python main.py

# Build web
flet build web .

# Serve locally
python3 -m http.server 8080 --directory build/web
```

## 📁 Project Structure

```
beauty_shelf/
├── main.py              # Entry point, app initialization
├── database.py          # Data layer (SQLite desktop, JSON web)
├── models.py            # Data models
├── categories.py         # Product categories configuration
├── notifications.py      # Push notification service
├── pages/
│   ├── home.py          # Main page
│   └── settings.py      # Settings page
├── widgets/
│   ├── product_card.py   # Product display card
│   ├── product_form.py  # Add/Edit modal form
│   ├── category_picker.py # Category selector
│   └── empty_state.py   # Empty list placeholder
└── requirements.txt     # Dependencies
```

## 🎨 Design Guidelines

### Colors
- Primary: `#E8B4BC` (пыльная роза)
- Background: `#FDF9FA` (тёплый белый)
- Text: `#2D2D2D` (тёмно-серый)
- Secondary text: `#8A8A8A`

### Typography
- Use `ft.Text` with `size=14` for body
- `size=16-20` for headings
- `weight=ft.FontWeight.W_600` for emphasis

### Spacing
- Card padding: 12-16px
- Grid gap: 12px
- Border radius: 12-16px

## 🧪 Testing

### Desktop
```bash
python main.py
```

### Web
```bash
# Build
flet build web .

# Serve (for mobile testing)
python3 -m http.server 8080 --directory build/web
```

## 🔄 Web vs Desktop

| Feature | Desktop | Web |
|---------|---------|-----|
| Database | SQLite | JSON file |
| Notifications | System notifications | In-app only |
| Storage | Local file | Browser localStorage |

## 📝 Making Changes

1. **Test locally first** - Run `python main.py` before committing
2. **Test web build** - Run `flet build web .` to catch Pyodide issues
3. **No external dependencies for web** - sqlite3, threading don't work in browser
4. **Check requirements.txt** - No comments, simple format for Pyodide

## ⚠️ Common Issues

### "Module not found: sqlite3"
→ Use JSON storage for web-compatible features

### "Black screen on mobile"
→ Check browser console for Python errors

### "InvalidRequirement" in build
→ Remove comments from requirements.txt

### Icon errors
→ Use `ft.icons.Icons.ICON_NAME` (new Flet API)

## 🏷️ Versioning

```bash
# Create a version tag
git tag -a v0.2.0 -m "New features"
git push origin main --tags
```
