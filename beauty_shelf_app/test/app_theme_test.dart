import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polochka/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTheme.instance.resetCategoriesForTest();
    AppTheme.instance.applyLoadedDarkMode(false);
    AppTheme.instance.applyPreset(
      const Color(0xFFE8B4BC),
      const Color(0xFFFDF9FA),
    );
  });

  group('theme background', () {
    test('applyPreset applies the chosen background', () {
      AppTheme.instance.applyPreset(
        const Color(0xFFB4A7E8),
        const Color(0xFFF5F3FA),
      );
      expect(AppTheme.instance.backgroundColor.toARGB32(), 0xFFF5F3FA);
    });

    test('adjustColors no longer resets the chosen background', () {
      AppTheme.instance.applyPreset(
        const Color(0xFFA7E8C4),
        const Color(0xFFF3FAF5),
      );
      AppTheme.instance.adjustColors();
      expect(AppTheme.instance.backgroundColor.toARGB32(), 0xFFF3FAF5);
    });
  });

  group('built-in categories', () {
    test('a built-in category can be removed', () {
      expect(
        AppTheme.instance.getCategoriesByType('care').containsKey('cream'),
        isTrue,
      );

      AppTheme.instance.removeCategory('care', 'cream');

      expect(
        AppTheme.instance.getCategoriesByType('care').containsKey('cream'),
        isFalse,
      );
      expect(
        AppTheme.instance.categories['care']!.containsKey('cream'),
        isFalse,
      );
    });

    test('a removed built-in stays removed after reordering', () {
      AppTheme.instance.removeCategory('decorative', 'mascara');
      final visible =
          AppTheme.instance.getCategoriesByType('decorative').keys.toList();

      AppTheme.instance.reorderCategories('decorative', visible.reversed.toList());

      expect(
        AppTheme.instance.getCategoriesByType('decorative').containsKey('mascara'),
        isFalse,
      );
    });

    test('re-adding a removed built-in key restores it', () {
      AppTheme.instance.removeCategory('care', 'serum');
      expect(
        AppTheme.instance.getCategoriesByType('care').containsKey('serum'),
        isFalse,
      );

      AppTheme.instance.addCategory('care', 'serum', 'Сыворотка (своя)');

      expect(
        AppTheme.instance.getCategoriesByType('care')['serum'],
        'Сыворотка (своя)',
      );
    });
  });
}
