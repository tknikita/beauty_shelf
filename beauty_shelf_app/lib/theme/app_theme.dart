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

  /// User-selected light-mode background. [backgroundColor] is derived from
  /// this (or the dark palette) inside [adjustColors], so a chosen preset
  /// background is not clobbered by subsequent [adjustColors] passes.
  Color _lightBackgroundColor = _lightBackground;

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

  /// Custom category groups (one-level subcategories): `type -> groupKey -> name`.
  Map<String, Map<String, String>> customGroups = {};

  /// Parent group of a leaf, stored as `type|leafKey -> groupKey`. Overrides
  /// the built-in assignment so built-in leaves can be reorganised.
  Map<String, String> leafParent = {};

  /// Built-in categories hidden by the user, stored as `type|key` entries.
  /// Needed because built-ins come from [_getDefaultCategories] and would
  /// otherwise reappear after removal.
  final Set<String> _removedCategories = {};

  /// Built-in groups hidden by the user, stored as `type|groupKey`.
  final Set<String> _removedGroups = {};

  bool isCategoryRemoved(String type, String key) =>
      _removedCategories.contains('$type|$key');

  /// Clears custom and hidden categories. Test-only helper.
  @visibleForTesting
  void resetCategoriesForTest() {
    customCategories.clear();
    customGroups.clear();
    leafParent.clear();
    _removedCategories.clear();
    _removedGroups.clear();
  }

  // Storage keys
  static const _keyDark = 'beauty_shelf_dark';
  static const _keyTheme = 'beauty_shelf_theme';
  static const _keyCategories = 'beauty_shelf_categories';
  static const _keyRemovedCategories = 'beauty_shelf_removed_categories';
  static const _keyGroups = 'beauty_shelf_groups';
  static const _keyLeafParent = 'beauty_shelf_leaf_parent';
  static const _keyRemovedGroups = 'beauty_shelf_removed_groups';

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _applyDarkMode();
    _saveDarkMode();
    notifyListeners();
  }

  /// Apply a dark-mode value loaded from storage and notify listeners.
  ///
  /// Kept as a public method so top-level loaders don't call the protected
  /// [notifyListeners] directly.
  void applyLoadedDarkMode(bool dark) {
    _isDarkMode = dark;
    _applyDarkMode();
    notifyListeners();
  }

  void _applyDarkMode() {
    if (_isDarkMode) {
      textColor = _darkText;
      textLightColor = _darkTextLight;
      backgroundColor = _darkBackground;
      surfaceColor = const Color(0xFF2A2A2A);
      borderColor = _darkBorder;
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
      careTypeBgColor = const Color(0xFF0D2744);
      decorativeTypeBgColor = const Color(0xFF2D1A3D);
    } else {
      textColor = _lightText;
      textLightColor = _lightTextLight;
      backgroundColor = _lightBackground;
      surfaceColor = Colors.white;
      borderColor = _lightBorder;
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
      careTypeBgColor = const Color(0xFFE3F2FD);
      decorativeTypeBgColor = const Color(0xFFF3E5F5);
    }
    adjustColors();
  }
  
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
    // Always store the chosen light-mode background so it applies whenever
    // the user switches back to light mode (in dark mode the dark palette is
    // used regardless).
    _lightBackgroundColor = background;
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
    
    // Generate status colors dynamically from primary hue
    _generateStatusColors(hsl);
    
    if (_isDarkMode) {
      backgroundColor = _darkBackground;
      surfaceColor = const Color(0xFF2A2A2A);
      borderColor = _darkBorder;
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
      careTypeBgColor = const Color(0xFF0D2744);
      decorativeTypeBgColor = const Color(0xFF2D1A3D);
    } else {
      backgroundColor = _lightBackgroundColor;
      surfaceColor = Colors.white;
      borderColor = _lightBorder;
      selectionColor = const Color(0xFFE8B4BC);
      inputFocusColor = const Color(0xFFE8B4BC);
      careTypeBgColor = const Color(0xFFE3F2FD);
      decorativeTypeBgColor = const Color(0xFFF3E5F5);
    }
  }
  
  void _generateStatusColors(HSLColor baseHsl) {
    // Expired: warm red-orange hue (alert)
    final expiredHue = (baseHsl.hue + 20) % 360;
    expiredColor = HSLColor.fromAHSL(1.0, expiredHue, 0.7, _isDarkMode ? 0.7 : 0.45).toColor();
    expiredBgColor = HSLColor.fromAHSL(1.0, expiredHue, 0.5, _isDarkMode ? 0.12 : 0.94).toColor();

    // Today: urgent orange
    final todayHue = (baseHsl.hue + 30) % 360;
    todayColor = HSLColor.fromAHSL(1.0, todayHue, 0.8, _isDarkMode ? 0.65 : 0.5).toColor();
    todayBgColor = HSLColor.fromAHSL(1.0, todayHue, 0.6, _isDarkMode ? 0.15 : 0.95).toColor();

    // Warning: golden yellow
    final warningHue = (baseHsl.hue - 10 + 360) % 360;
    warningColor = HSLColor.fromAHSL(1.0, warningHue, 0.85, _isDarkMode ? 0.6 : 0.55).toColor();
    warningBgColor = HSLColor.fromAHSL(1.0, warningHue, 0.6, _isDarkMode ? 0.15 : 0.97).toColor();

    // Success/OK: green, shifted from primary hue
    final successHue = (baseHsl.hue + 140) % 360;
    successColor = HSLColor.fromAHSL(1.0, successHue, 0.5, _isDarkMode ? 0.6 : 0.45).toColor();
    successBgColor = HSLColor.fromAHSL(1.0, successHue, 0.4, _isDarkMode ? 0.12 : 0.94).toColor();

    // Neutral: based on primary with low saturation
    neutralColor = HSLColor.fromAHSL(1.0, baseHsl.hue, 0.15, _isDarkMode ? 0.7 : 0.4).toColor();
    neutralBgColor = HSLColor.fromAHSL(1.0, baseHsl.hue, 0.1, _isDarkMode ? 0.15 : 0.97).toColor();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyTheme,
        '${primaryColor.toARGB32()},${_lightBackgroundColor.toARGB32()}',
      );
    } catch (e) {
      debugPrint('_saveToStorage error: $e');
    }
  }

  // Categories management
  void addCategory(String type, String key, String name, {String? groupKey}) {
    if (!customCategories.containsKey(type)) {
      customCategories[type] = {};
    }
    customCategories[type]![key] = name;
    // Re-adding a previously removed built-in makes it visible again.
    _removedCategories.remove('$type|$key');
    if (groupKey != null) {
      leafParent['$type|$key'] = groupKey;
    }
    _saveCategories();
    notifyListeners();
  }

  void removeCategory(String type, String key) {
    customCategories[type]?.remove(key);
    leafParent.remove('$type|$key');
    // Remember the removal so a built-in category does not reappear from
    // [_getDefaultCategories] on the next rebuild.
    _removedCategories.add('$type|$key');
    _saveCategories();
    notifyListeners();
  }

  /// Adds a one-level group (subcategory bucket).
  void addGroup(String type, String key, String name) {
    customGroups.putIfAbsent(type, () => {})[key] = name;
    _removedGroups.remove('$type|$key');
    _saveCategories();
    notifyListeners();
  }

  /// Renames a group. Works for built-ins too (stored as an override).
  void renameGroup(String type, String key, String name) {
    customGroups.putIfAbsent(type, () => {})[key] = name;
    _removedGroups.remove('$type|$key');
    _saveCategories();
    notifyListeners();
  }

  /// Hides a group (built-in or custom). Its leaves become un-grouped.
  void removeGroup(String type, String key) {
    customGroups[type]?.remove(key);
    _removedGroups.add('$type|$key');
    // Leaves that pointed at this group fall back to their default/un-grouped.
    leafParent.removeWhere((k, v) => v == key && k.startsWith('$type|'));
    _saveCategories();
    notifyListeners();
  }

  /// Group key that [leafKey] belongs to, or null when un-grouped.
  String? groupOf(String type, String leafKey) =>
      leafParent['$type|$leafKey'] ?? _getDefaultLeafParent()[type]?[leafKey];

  /// Serializable snapshot of theme + category state for backups.
  Map<String, dynamic> toBackup() => {
        'customCategories': customCategories,
        'customGroups': customGroups,
        'leafParent': leafParent,
        'removedCategories': _removedCategories.toList(),
        'removedGroups': _removedGroups.toList(),
        'primary': primaryColor.toARGB32(),
        'background': _lightBackgroundColor.toARGB32(),
        'dark': _isDarkMode,
      };

  /// Restores state produced by [toBackup] and persists it.
  void applyBackup(Map<String, dynamic> data) {
    try {
      customCategories = _readNested(data['customCategories']);
      customGroups = _readNested(data['customGroups']);
      leafParent = _readFlat(data['leafParent']);
      _removedCategories
        ..clear()
        ..addAll(((data['removedCategories'] as List?) ?? const [])
            .map((e) => e.toString()));
      _removedGroups
        ..clear()
        ..addAll(((data['removedGroups'] as List?) ?? const [])
            .map((e) => e.toString()));

      if (data['primary'] is int) primaryColor = Color(data['primary'] as int);
      if (data['background'] is int) {
        _lightBackgroundColor = Color(data['background'] as int);
      }
      _isDarkMode = data['dark'] == true;
      adjustColors();

      _saveCategories();
      _saveToStorage();
      _saveDarkMode();
      notifyListeners();
    } catch (e) {
      debugPrint('applyBackup error: $e');
    }
  }

  Map<String, Map<String, String>> _readNested(dynamic src) {
    final out = <String, Map<String, String>>{};
    if (src is Map) {
      src.forEach((k, v) {
        final inner = <String, String>{};
        if (v is Map) {
          v.forEach((ik, iv) => inner['$ik'] = '$iv');
        }
        out['$k'] = inner;
      });
    }
    return out;
  }

  Map<String, String> _readFlat(dynamic src) {
    final out = <String, String>{};
    if (src is Map) {
      src.forEach((k, v) => out['$k'] = '$v');
    }
    return out;
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCategories, _encodeMap(customCategories));
      await prefs.setString(_keyRemovedCategories, _removedCategories.join(';'));
      await prefs.setString(_keyGroups, _encodeMap(customGroups));
      await prefs.setString(_keyLeafParent, _encodeFlat(leafParent));
      await prefs.setString(_keyRemovedGroups, _removedGroups.join(';'));
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

  String _encodeFlat(Map<String, String> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join(';');

  Map<String, String> _decodeFlat(String encoded) {
    final result = <String, String>{};
    if (encoded.isEmpty) return result;
    for (final entry in encoded.split(';')) {
      final idx = entry.indexOf('=');
      if (idx > 0) {
        result[entry.substring(0, idx)] = entry.substring(idx + 1);
      }
    }
    return result;
  }

  Map<String, Map<String, String>> get categories {
    final defaults = _getDefaultCategories();
    final result = <String, Map<String, String>>{};
    for (final type in defaults.keys) {
      result[type] = getCategoriesByType(type);
    }
    return result;
  }

  /// Visible leaves for [type], sorted by display name: built-ins minus removed
  /// ones, overridden by custom categories.
  Map<String, String> getCategoriesByType(String type) {
    final result = <String, String>{};
    final defaults = _getDefaultCategories()[type] ?? {};
    for (final entry in defaults.entries) {
      if (!isCategoryRemoved(type, entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    final custom = customCategories[type] ?? {};
    for (final entry in custom.entries) {
      if (!isCategoryRemoved(type, entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return _sortedByName(result);
  }

  /// Groups (subcategory buckets) for [type]: built-ins in a fixed order
  /// (minus hidden ones), custom groups appended sorted by name.
  Map<String, String> getGroupsByType(String type) {
    final result = <String, String>{};
    (_getDefaultGroups()[type] ?? const {}).forEach((k, v) {
      if (!_removedGroups.contains('$type|$k')) result[k] = v;
    });
    final custom = customGroups[type] ?? {};
    final sorted = custom.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    for (final e in sorted) {
      if (_removedGroups.contains('$type|${e.key}')) continue;
      result[e.key] = e.value;
    }
    return result;
  }

  /// Ready-to-render one-level tree for the settings / forms UI.
  List<CategoryGroup> getCategoryTree(String type) {
    final leaves = getCategoriesByType(type);
    final groups = getGroupsByType(type);
    final byGroup = <String?, Map<String, String>>{};
    for (final entry in leaves.entries) {
      final g = groupOf(type, entry.key);
      byGroup.putIfAbsent(g, () => {})[entry.key] = entry.value;
    }

    final result = <CategoryGroup>[];
    // Un-grouped leaves first (no parent, or parent that no longer exists).
    final ungrouped = <String, String>{};
    byGroup.forEach((g, items) {
      if (g == null || !groups.containsKey(g)) ungrouped.addAll(items);
    });
    if (ungrouped.isNotEmpty) {
      result.add(CategoryGroup(
        key: null,
        name: '',
        leaves: _sortedByName(ungrouped),
      ));
    }
    for (final g in groups.entries) {
      result.add(CategoryGroup(
        key: g.key,
        name: g.value,
        leaves: _sortedByName(byGroup[g.key] ?? const {}),
      ));
    }
    return result;
  }

  /// Leaf keys that a filter on [groupOrLeaf] should match: the leaf itself, or
  /// every child when a group key is given.
  Set<String> resolveCategoryFilter(String type, String groupOrLeaf) {
    final groupLeaves = getCategoryTree(type)
        .where((g) => g.key == groupOrLeaf)
        .expand((g) => g.leaves.keys)
        .toSet();
    if (groupLeaves.isNotEmpty) return groupLeaves;
    return {groupOrLeaf};
  }

  Map<String, String> _sortedByName(Map<String, String> data) {
    final sorted = data.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return {for (final e in sorted) e.key: e.value};
  }

  Map<String, Map<String, String>> _getDefaultCategories() {
    return {
      'care': {
        'basic_care': 'Базовая уходовая',
        'cleanser': 'Очищающее средство',
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

  /// Built-in one-level groups (subcategory buckets) per type.
  Map<String, Map<String, String>> _getDefaultGroups() {
    return {
      'care': {
        'cleansing': 'Очищение и тонизирование',
        'face_care': 'Уход за лицом',
        'creams': 'Кремы',
      },
      'decorative': {
        'complexion': 'Тон и коррекция',
        'sculpting': 'Скульптурирование',
        'eyes': 'Глаза',
      },
    };
  }

  /// Built-in leaf -> group assignment. Leaves absent here are un-grouped.
  Map<String, Map<String, String>> _getDefaultLeafParent() {
    return {
      'care': {
        'basic_care': 'cleansing',
        'cleanser': 'cleansing',
        'tonic': 'cleansing',
        'serum': 'face_care',
        'mask': 'face_care',
        'special': 'face_care',
        'sunscreen': 'face_care',
        'cream': 'creams',
        'face_cream': 'creams',
        'eye_cream': 'creams',
      },
      'decorative': {
        'base': 'complexion',
        'tone': 'complexion',
        'concealer': 'complexion',
        'powder': 'complexion',
        'blush': 'sculpting',
        'bronzer': 'sculpting',
        'highlighter': 'sculpting',
        'eyeshadow': 'eyes',
        'eyeliner': 'eyes',
        'mascara': 'eyes',
        'eyebrows': 'eyes',
      },
    };
  }
}

/// A one-level category group with its leaves, ready for rendering.
class CategoryGroup {
  final String? key;
  final String name;
  final Map<String, String> leaves;

  const CategoryGroup({required this.key, required this.name, required this.leaves});

  bool get isUngrouped => key == null;
}

Future<void> loadDarkMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('beauty_shelf_dark');
    AppTheme.instance.applyLoadedDarkMode(saved == '1');
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
    final removed = prefs.getString('beauty_shelf_removed_categories');
    if (removed != null && removed.isNotEmpty) {
      AppTheme.instance._removedCategories
        ..clear()
        ..addAll(removed.split(';').where((e) => e.isNotEmpty));
    }
    final groups = prefs.getString('beauty_shelf_groups');
    if (groups != null && groups.isNotEmpty) {
      AppTheme.instance.customGroups = AppTheme.instance._decodeMap(groups);
    }
    final parents = prefs.getString('beauty_shelf_leaf_parent');
    if (parents != null && parents.isNotEmpty) {
      AppTheme.instance.leafParent = AppTheme.instance._decodeFlat(parents);
    }
    final removedGroups = prefs.getString('beauty_shelf_removed_groups');
    if (removedGroups != null && removedGroups.isNotEmpty) {
      AppTheme.instance._removedGroups
        ..clear()
        ..addAll(removedGroups.split(';').where((e) => e.isNotEmpty));
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
          AppTheme.instance._lightBackgroundColor = Color(bg);
          AppTheme.instance.adjustColors();
        }
      }
    }
  } catch (e) {
    debugPrint('loadThemeFromStorage error: $e');
  }
}
