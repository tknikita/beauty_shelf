import 'package:flutter/material.dart';
// ignore: avoid_web_libraries
import 'dart:html' as html;

class AppTheme extends ChangeNotifier {
  static final AppTheme _instance = AppTheme._();
  static AppTheme get instance => _instance;
  factory AppTheme() => _instance;
  AppTheme._();

  Color primaryColor = const Color(0xFFE8B4BC);
  Color primaryDarkColor = const Color(0xFFD49BA5);
  Color backgroundColor = const Color(0xFFFDF9FA);
  Color textColor = const Color(0xFF333333);
  Color textLightColor = const Color(0xFF8A8A8A);
  Color borderColor = const Color(0xFFE8E8E8);
  Color okColor = const Color(0xFF8FC9A3);
  Color okBgColor = const Color(0xFFF0F7F2);
  Color warningColor = const Color(0xFFE8A87C);
  Color warningBgColor = const Color(0xFFFDF5F0);
  Color dangerColor = const Color(0xFFD9848C);
  Color dangerBgColor = const Color(0xFFFDF0F2);

  // Custom categories
  Map<String, Map<String, String>> customCategories = {};

  void applyPreset(Color primary, Color background) {
    primaryColor = primary;
    backgroundColor = background;
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
  }

  void _saveToStorage() {
    try {
      html.window.localStorage['beauty_shelf_theme'] =
        '${primaryColor.value},${backgroundColor.value}';
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
          AppTheme.instance.adjustColors();
        }
      }
    }
  } catch (e) {
    // localStorage not available
  }
}
