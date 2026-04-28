import 'dart:html' as html;
import 'dart:ui';
import 'app_theme.dart';

void loadThemeFromStorage() {
  try {
    final saved = html.window.localStorage['beauty_shelf_theme'];
    if (saved != null && saved.isNotEmpty) {
      final parts = saved.split(',');
      if (parts.length >= 2) {
        final primary = int.tryParse(parts[0]);
        final bg = int.tryParse(parts[1]);
        if (primary != null && bg != null) {
          AppTheme.instance.primaryColor = Color(primary);
          AppTheme.instance.backgroundColor = Color(bg);
          AppTheme.instance.adjustColors();
        }
      }
    }
  } catch (e) {
    // localStorage not available
  }
}
