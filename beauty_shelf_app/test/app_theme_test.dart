import 'dart:convert';

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

    test('built-in leaves are grouped into subcategories', () {
      final tree = AppTheme.instance.getCategoryTree('care');
      final creams = tree.firstWhere((g) => g.key == 'creams');
      expect(creams.name, 'Кремы');
      expect(
        creams.leaves.keys,
        containsAll(['cream', 'face_cream', 'eye_cream']),
      );
    });

    test('a new category can be added into a group', () {
      AppTheme.instance.addCategory('care', 'custom_x', 'Мой крем', groupKey: 'creams');

      final tree = AppTheme.instance.getCategoryTree('care');
      final creams = tree.firstWhere((g) => g.key == 'creams');

      expect(creams.leaves['custom_x'], 'Мой крем');
      expect(AppTheme.instance.groupOf('care', 'custom_x'), 'creams');
    });

    test('removing a custom group ungroups its leaves', () {
      AppTheme.instance.addGroup('care', 'g1', 'Раздел');
      AppTheme.instance.addCategory('care', 'leaf1', 'Лист', groupKey: 'g1');
      expect(AppTheme.instance.groupOf('care', 'leaf1'), 'g1');

      AppTheme.instance.removeGroup('care', 'g1');

      expect(AppTheme.instance.getGroupsByType('care').containsKey('g1'), isFalse);
      // Custom leaf had no built-in parent, so it becomes un-grouped.
      expect(AppTheme.instance.groupOf('care', 'leaf1'), isNull);
    });

    test('a built-in group can be renamed', () {
      AppTheme.instance.renameGroup('care', 'creams', 'Кремы и сыворотки');
      expect(
        AppTheme.instance.getGroupsByType('care')['creams'],
        'Кремы и сыворотки',
      );
    });

    test('a built-in group can be removed, its leaves become un-grouped', () {
      AppTheme.instance.removeGroup('care', 'creams');

      expect(
        AppTheme.instance.getGroupsByType('care').containsKey('creams'),
        isFalse,
      );
      final tree = AppTheme.instance.getCategoryTree('care');
      final ungrouped = tree.firstWhere((g) => g.isUngrouped);
      expect(ungrouped.leaves.containsKey('cream'), isTrue);
    });

    test('a group filter resolves to its children', () {
      expect(
        AppTheme.instance.resolveCategoryFilter('care', 'creams'),
        containsAll(['cream', 'face_cream', 'eye_cream']),
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

  group('backup state', () {
    test('toBackup/applyBackup round-trips categories and theme', () {
      AppTheme.instance.addGroup('care', 'g2', 'Набор');
      AppTheme.instance.addCategory('care', 'custom_b', 'Моё', groupKey: 'g2');
      AppTheme.instance.removeCategory('decorative', 'mascara');
      AppTheme.instance.removeGroup('decorative', 'eyes');
      AppTheme.instance.applyPreset(
        const Color(0xFFA7E8C4),
        const Color(0xFFF3FAF5),
      );

      // Simulate going through JSON, as the real backup does.
      final snapshot =
          jsonDecode(jsonEncode(AppTheme.instance.toBackup())) as Map<String, dynamic>;

      // Wipe, then restore.
      AppTheme.instance.resetCategoriesForTest();
      AppTheme.instance.applyPreset(
        const Color(0xFFE8B4BC),
        const Color(0xFFFDF9FA),
      );
      AppTheme.instance.applyBackup(snapshot);

      expect(AppTheme.instance.getGroupsByType('care')['g2'], 'Набор');
      expect(
        AppTheme.instance
            .getCategoryTree('care')
            .firstWhere((g) => g.key == 'g2')
            .leaves['custom_b'],
        'Моё',
      );
      expect(
        AppTheme.instance.getCategoriesByType('decorative').containsKey('mascara'),
        isFalse,
      );
      expect(
        AppTheme.instance.getGroupsByType('decorative').containsKey('eyes'),
        isFalse,
      );
      expect(AppTheme.instance.primaryColor.toARGB32(), 0xFFA7E8C4);
      expect(AppTheme.instance.backgroundColor.toARGB32(), 0xFFF3FAF5);
    });
  });
}
