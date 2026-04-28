import 'package:flutter/material.dart';
// ignore: avoid_web_libraries
import 'dart:html' as html;

class AppTheme extends ChangeNotifier {
  static final AppTheme _instance = AppTheme._();
  static AppTheme get instance => _instance;
  factory AppTheme() => _instance;
  AppTheme._();

  // Light theme colors
  static const _lightPrimary = Color(0xFFE8B4BC);
  static const _lightPrimaryDark = Color(0xFFD49BA5);
  static const _lightBackground = Color(0xFFFDF9FA);
  static const _lightText = Color(0xFF333333);
  static const _lightTextLight = Color(0xFF8A8A8A);
  static const _lightBorder = Color(0xFFE8E8E8);

  // Dark theme colors
  static const _darkPrimary = Color(0xFFE8B4BC);
  static const _darkPrimaryDark = Color(0xFFD49BA5);
  static const _darkBackground = Color(0xFF1A1A1A);
  static const _darkText = Color(0xFFF5F5F5);
  static const _darkTextLight = Color(0xFFAAAAAA);
  static const _darkBorder = Color(0xFF333333);

  Color primaryColor = _lightPrimary;
  Color primaryDarkColor = _lightPrimaryDark;
  Color backgroundColor = _lightBackground;
  Color surfaceColor = Colors.white;
  Color textColor = _lightText;
  Color textLightColor = _lightTextLight;
  Color borderColor = _lightBorder;
  Color okColor = const Color(0xFF8FC9A3);
  Color okBgColor = const Color(0xFFF0F7F2);
  Color warningColor = const Color(0xFFE8A87C);
  Color warningBgColor = const Color(0xFFFDF5F0);
  Color dangerColor = const Color(0xFFD9848C);
  Color dangerBgColor = const Color(0xFFFDF0F2);

  // Selection/focus colors
  Color selectionColor = const Color(0xFFE8B4BC);
  Color inputFocusColor = const Color(0xFFE8B4BC);

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Custom categories
  Map<String, Map<String, String>> customCategories = {};

  void toggleDarkMode() {
    // Save primary before switching
    _savedPrimaryColor = primaryColor;
    AppTheme._instancePrimarySet = true;
    _isDarkMode = !_isDarkMode;
    _applyDarkMode();
    _saveDarkMode();
    notifyListeners();
  }

  void _applyDarkMode() {
    // Keep user's chosen primary color
    if (_isDarkMode) {
      backgroundColor = _darkBackground;
      surfaceColor = const Color(0xFF2A2A2A);
      borderColor = _darkBorder;
      // Brighter badge colors for dark mode visibility
      okBgColor = const Color(0xFF1B3D22);
      okColor = const Color(0xFF7DD49A);
      warningBgColor = const Color(0xFF3D2E1B);
      warningColor = const Color(0xFFE8C77C);
      dangerBgColor = const Color(0xFF3D1B1B);
      dangerColor = const Color(0xFFE87C7C);
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
    } else {
      backgroundColor = _lightBackground;
      surfaceColor = Colors.white;
      borderColor = _lightBorder;
      okBgColor = const Color(0xFFF0F7F2);
      warningBgColor = const Color(0xFFFDF5F0);
      dangerBgColor = const Color(0xFFFDF0F2);
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
    }
    // Recalculate text colors from primary
    adjustColors();
  }
  
  static bool _instancePrimarySet = false;
  Color _savedPrimaryColor = _lightPrimary;

  void _saveDarkMode() {
    try {
      html.window.localStorage['beauty_shelf_dark'] = _isDarkMode ? '1' : '0';
    } catch (e) {
      // localStorage not available
    }
  }

  void applyPreset(Color primary, Color background) {
    primaryColor = primary;
    _savedPrimaryColor = primary;
    // In dark mode, don't change background/surface colors
    if (!_isDarkMode) {
      backgroundColor = background;
    }
    adjustColors();
    _saveToStorage();
    notifyListeners();
  }

  void setCustomColors(Color primary, Color background) {
    applyPreset(primary, background);
  }

  void adjustColors() {
    final hsl = HSLColor.fromColor(primaryColor);
    primaryDarkColor = HSLColor.fromAHSL(
      1.0, hsl.hue, hsl.saturation,
      (hsl.lightness - 0.1).clamp(0.0, 1.0)
    ).toColor();
    
    // Text color tinted with primary (more saturated, readable lightness)
    if (_isDarkMode) {
      // Dark mode: light text with primary tint
      textColor = HSLColor.fromAHSL(
        1.0, hsl.hue, 
        (hsl.saturation * 0.5).clamp(0.0, 1.0),
        0.85
      ).toColor();
      textLightColor = HSLColor.fromAHSL(
        1.0, hsl.hue,
        (hsl.saturation * 0.3).clamp(0.0, 1.0),
        0.7
      ).toColor();
    } else {
      // Light mode: dark text with primary tint
      textColor = HSLColor.fromAHSL(
        1.0, hsl.hue, 
        (hsl.saturation * 0.6).clamp(0.0, 1.0),
        0.25
      ).toColor();
      textLightColor = HSLColor.fromAHSL(
        1.0, hsl.hue,
        (hsl.saturation * 0.4).clamp(0.0, 1.0),
        0.5
      ).toColor();
    }
  }

  void _saveToStorage() {
    try {
      html.window.localStorage['beauty_shelf_theme'] =
        '${primaryColor.value},${backgroundColor.value},${_savedPrimaryColor.value}';
    } catch (e) {
      // localStorage not available
    }
  }

  // View mode persistence
  bool isTableView = false;

  void setTableView(bool value) {
    isTableView = value;
    _saveViewMode();
    notifyListeners();
  }

  void _saveViewMode() {
    try {
      html.window.localStorage['beauty_shelf_view'] = isTableView ? 'table' : 'card';
    } catch (e) {
      // localStorage not available
    }
  }

  // Categories management
  void addCategory(String type, String key, String name) {
    if (!customCategories.containsKey(type)) {
      customCategories[type] = {};
    }
    customCategories[type]![key] = name;
    _saveCategories();
    notifyListeners();
  }

  void removeCategory(String type, String key) {
    customCategories[type]?.remove(key);
    _saveCategories();
    notifyListeners();
  }

  void reorderCategories(String type, List<String> keys) {
    final reordered = <String, String>{};
    for (final key in keys) {
      final name = _getDefaultCategories()[type]?[key] ?? customCategories[type]?[key];
      if (name != null) {
        reordered[key] = name;
      }
    }
    customCategories[type] = reordered;
    _saveCategories();
    notifyListeners();
  }

  void _saveCategories() {
    try {
      final encoded = customCategories.map((type, cats) =>
        MapEntry(type, cats.map((k, v) => MapEntry(k, v))));
      html.window.localStorage['beauty_shelf_categories'] = _encodeMap(encoded);
    } catch (e) {
      // localStorage not available
    }
  }

  String _encodeMap(Map<String, Map<String, String>> data) {
    return data.entries
        .map((e) => '${e.key}:${e.value.entries.map((v) => '${v.key}=${v.value}').join(',')}')
        .join(';');
  }

  Map<String, Map<String, String>> _decodeMap(String encoded) {
    final result = <String, Map<String, String>>{};
    if (encoded.isEmpty) return result;
    for (final entry in encoded.split(';')) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        result[parts[0]] = {};
        for (final cat in parts[1].split(',')) {
          final catParts = cat.split('=');
          if (catParts.length == 2) {
            result[parts[0]]![catParts[0]] = catParts[1];
          }
        }
      }
    }
    return result;
  }

  Map<String, Map<String, String>> get categories {
    final defaults = _getDefaultCategories();
    final result = <String, Map<String, String>>{};
    for (final type in defaults.keys) {
      final def = defaults[type]!;
      final custom = customCategories[type] ?? {};
      result[type] = Map<String, String>.from(def)..addAll(custom);
    }
    return result;
  }

  Map<String, String> getCategoriesByType(String type) {
    final defaults = _getDefaultCategories()[type] ?? {};
    final custom = customCategories[type] ?? {};
    return Map<String, String>.from(defaults)..addAll(custom);
  }

  Map<String, Map<String, String>> _getDefaultCategories() {
    return {
      'care': {
        'basic_care': 'Базовая уходовая',
        'cleanser': 'Очищение',
        'tonic': 'Тоник',
        'serum': 'Сыворотка',
        'cream': 'Крем',
        'face_cream': 'Крем для лица',
        'eye_cream': 'Крем для глаз',
        'mask': 'Маска',
        'sunscreen': 'Солнцезащита',
        'special': 'Специальный уход',
      },
      'decorative': {
        'base': 'База',
        'tone': 'Тональное средство',
        'concealer': 'Консилер',
        'powder': 'Пудра',
        'blush': 'Румяна',
        'bronzer': 'Бронзер',
        'highlighter': 'Хайлайтер',
        'eyeshadow': 'Тени для век',
        'eyeliner': 'Подводка',
        'mascara': 'Тушь',
        'eyebrows': 'Брови',
        'lips': 'Губы',
        'nails': 'Ногти',
      },
    };
  }
}

void loadViewMode() {
  try {
    final saved = html.window.localStorage['beauty_shelf_view'];
    if (saved == 'table') {
      AppTheme.instance.isTableView = true;
    }
  } catch (e) {
    // localStorage not available
  }
}

void loadDarkMode() {
  try {
    final saved = html.window.localStorage['beauty_shelf_dark'];
    if (saved == '1') {
      AppTheme.instance._isDarkMode = true;
      AppTheme.instance._applyDarkMode();
      AppTheme.instance.notifyListeners();
    }
  } catch (e) {
    // localStorage not available
  }
}

void loadCategories() {
  try {
    final saved = html.window.localStorage['beauty_shelf_categories'];
    if (saved != null && saved.isNotEmpty) {
      AppTheme.instance.customCategories = AppTheme.instance._decodeMap(saved);
    }
  } catch (e) {
    // localStorage not available
  }
}

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
          AppTheme.instance._savedPrimaryColor = Color(primary);
          AppTheme._instancePrimarySet = true;
          AppTheme.instance.adjustColors();
        }
      }
    }
  } catch (e) {
    // localStorage not available
  }
}
