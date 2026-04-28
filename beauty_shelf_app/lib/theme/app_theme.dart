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
