import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Status colors
  Color expiredColor = const Color(0xFFC62828);
  Color expiredBgColor = const Color(0xFFFFEBEE);
  Color todayColor = const Color(0xFFEF6C00);
  Color todayBgColor = const Color(0xFFFFF3E0);
  Color warningColor = const Color(0xFFF9A825);
  Color warningBgColor = const Color(0xFFFFFDE7);
  Color neutralColor = const Color(0xFF616161);
  Color neutralBgColor = const Color(0xFFF5F5F5);
  Color successColor = const Color(0xFF2E7D32);
  Color successBgColor = const Color(0xFFE8F5E9);

  // Type badge colors
  Color careTypeColor = const Color(0xFF2196F3);
  Color careTypeBgColor = const Color(0xFFE3F2FD);
  Color decorativeTypeColor = const Color(0xFF9C27B0);
  Color decorativeTypeBgColor = const Color(0xFFF3E5F5);

  // Selection/focus colors
  Color selectionColor = const Color(0xFFE8B4BC);
  Color inputFocusColor = const Color(0xFFE8B4BC);

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Custom categories
  Map<String, Map<String, String>> customCategories = {};

  // Storage keys
  static const _keyDark = 'beauty_shelf_dark';
  static const _keyTheme = 'beauty_shelf_theme';
  static const _keyCategories = 'beauty_shelf_categories';

  void toggleDarkMode() {
    _savedPrimaryColor = primaryColor;
    _instancePrimarySet = true;
    _isDarkMode = !_isDarkMode;
    _applyDarkMode();
    _saveDarkMode();
    notifyListeners();
  }

  void _applyDarkMode() {
    if (_isDarkMode) {
      backgroundColor = _darkBackground;
      surfaceColor = const Color(0xFF2A2A2A);
      borderColor = _darkBorder;
      expiredBgColor = const Color(0xFF3D1B1B);
      expiredColor = const Color(0xFFEF9A9A);
      todayBgColor = const Color(0xFF3D2E1B);
      todayColor = const Color(0xFFFFCC80);
      warningBgColor = const Color(0xFF3D3D1B);
      warningColor = const Color(0xFFFFF176);
      neutralBgColor = const Color(0xFF2A2A2A);
      neutralColor = const Color(0xFFBDBDBD);
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
      careTypeBgColor = const Color(0xFF0D2744);
      decorativeTypeBgColor = const Color(0xFF2D1A3D);
    } else {
      backgroundColor = _lightBackground;
      surfaceColor = Colors.white;
      borderColor = _lightBorder;
      expiredBgColor = const Color(0xFFFFEBEE);
      expiredColor = const Color(0xFFC62828);
      todayBgColor = const Color(0xFFFFF3E0);
      todayColor = const Color(0xFFEF6C00);
      warningBgColor = const Color(0xFFFFFDE7);
      warningColor = const Color(0xFFF9A825);
      neutralBgColor = const Color(0xFFF5F5F5);
      neutralColor = const Color(0xFF616161);
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
      careTypeBgColor = const Color(0xFFE3F2FD);
      decorativeTypeBgColor = const Color(0xFFF3E5F5);
    }
    adjustColors();
  }
  
  static bool _instancePrimarySet = false;
  Color _savedPrimaryColor = _lightPrimary;

  Future<void> _saveDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDark, _isDarkMode ? '1' : '0');
    } catch (e) {
      debugPrint('_saveDarkMode error: $e');
    }
  }

  void applyPreset(Color primary, Color background) {
    primaryColor = primary;
    _savedPrimaryColor = primary;
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
    
    if (_isDarkMode) {
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

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyTheme,
        '${primaryColor.toARGB32()},${backgroundColor.toARGB32()},${_savedPrimaryColor.toARGB32()}',
      );
    } catch (e) {
      debugPrint('_saveToStorage error: $e');
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

  Future<void> _saveCategories() async {
    try {
      final encoded = customCategories.map((type, cats) =>
        MapEntry(type, cats.map((k, v) => MapEntry(k, v))));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCategories, _encodeMap(encoded));
    } catch (e) {
      debugPrint('_saveCategories error: $e');
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

Future<void> loadDarkMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('beauty_shelf_dark');
    if (saved == '1') {
      AppTheme.instance._isDarkMode = true;
      AppTheme.instance._applyDarkMode();
      AppTheme.instance.notifyListeners();
    } else {
      AppTheme.instance._isDarkMode = false;
      AppTheme.instance._applyDarkMode();
    }
  } catch (e) {
    debugPrint('loadDarkMode error: $e');
  }
}

Future<void> loadCategories() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('beauty_shelf_categories');
    if (saved != null && saved.isNotEmpty) {
      AppTheme.instance.customCategories = AppTheme.instance._decodeMap(saved);
    }
  } catch (e) {
    debugPrint('loadCategories error: $e');
  }
}

Future<void> loadThemeFromStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('beauty_shelf_theme');
    if (saved != null && saved.isNotEmpty) {
      final parts = saved.split(',');
      if (parts.length >= 2) {
        final primary = int.tryParse(parts[0]);
        final bg = int.tryParse(parts[1]);
        if (primary != null && bg != null) {
          AppTheme.instance.primaryColor = Color(primary);
          AppTheme.instance._savedPrimaryColor = Color(primary);
          AppTheme._instancePrimarySet = true;
          
          if (!AppTheme.instance._isDarkMode) {
            AppTheme.instance.backgroundColor = Color(bg);
            AppTheme.instance.surfaceColor = Colors.white;
            AppTheme.instance.borderColor = AppTheme._lightBorder;
          }
          AppTheme.instance.adjustColors();
        }
      }
    }
  } catch (e) {
    debugPrint('loadThemeFromStorage error: $e');
  }
}
