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

  group('sort modes', () {
    test('auto orders groups and leaves by name', () {
      final tree = AppTheme.instance.getCategoryTree('care');
      final groupNames =
          tree.where((g) => !g.isUngrouped).map((g) => g.name).toList();
      final sorted = [...groupNames]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(groupNames, sorted);

      for (final g in tree) {
        final names = g.leaves.values.toList();
        final s = [...names]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        expect(names, s);
      }
    });

    test('manual mode persists group and leaf order, reset returns to auto', () {
      final groups = AppTheme.instance.getGroupsByType('care').keys.toList();
      AppTheme.instance.reorderGroups('care', groups.reversed.toList());
      expect(AppTheme.instance.isManualSort('care'), isTrue);
      expect(
        AppTheme.instance
            .getCategoryTree('care')
            .where((g) => !g.isUngrouped)
            .map((g) => g.key)
            .toList(),
        groups.reversed.toList(),
      );

      final creams =
          AppTheme.instance.getCategoryTree('care').firstWhere((g) => g.key == 'creams');
      final leafKeys = creams.leaves.keys.toList();
      AppTheme.instance.reorderLeaves('care', 'creams', leafKeys.reversed.toList());
      final after =
          AppTheme.instance.getCategoryTree('care').firstWhere((g) => g.key == 'creams');
      expect(after.leaves.keys.toList(), leafKeys.reversed.toList());

      AppTheme.instance.resetSort('care');
      expect(AppTheme.instance.isManualSort('care'), isFalse);
    });

    test('manual layout can move a leaf into an empty group and out again', () {
      AppTheme.instance.addGroup('care', 'empty_g', 'Пусто');

      // Move 'cream' into the empty group.
      AppTheme.instance.applyManualLayout(
        'care',
        ['empty_g', 'creams', 'cleansing', 'face_care'],
        {
          'empty_g': ['cream'],
          'creams': ['face_cream', 'eye_cream'],
          'cleansing': ['basic_care', 'cleanser', 'tonic'],
          'face_care': ['serum', 'mask', 'special', 'sunscreen'],
        },
      );
      expect(AppTheme.instance.groupOf('care', 'cream'), 'empty_g');
      expect(
        AppTheme.instance
            .getCategoryTree('care')
            .firstWhere((g) => g.key == 'empty_g')
            .leaves
            .keys
            .toList(),
        ['cream'],
      );

      // Then drag it to the very top (explicitly un-grouped).
      AppTheme.instance.applyManualLayout(
        'care',
        ['empty_g', 'creams', 'cleansing', 'face_care'],
        {
          'creams': ['face_cream', 'eye_cream'],
          'cleansing': ['basic_care', 'cleanser', 'tonic'],
          'face_care': ['serum', 'mask', 'special', 'sunscreen'],
          '': ['cream'],
        },
      );
      expect(AppTheme.instance.groupOf('care', 'cream'), isNull);
    });
  });

  group('product types', () {
    test('type can be renamed and hidden/restored', () {
      expect(AppTheme.instance.typeName('care'), 'Уходовая');

      AppTheme.instance.renameType('care', 'Уход');
      expect(AppTheme.instance.typeName('care'), 'Уход');

      AppTheme.instance.removeType('decorative');
      expect(AppTheme.instance.visibleTypes(), ['care']);
      expect(AppTheme.instance.isTypeRemoved('decorative'), isTrue);

      AppTheme.instance.restoreType('decorative');
      expect(AppTheme.instance.visibleTypes(), ['care', 'decorative']);
    });
  });

  group('backup state', () {
    test('toBackup/applyBackup round-trips categories and theme', () {
      AppTheme.instance.addGroup('care', 'g2', 'Набор');
      AppTheme.instance.addCategory('care', 'custom_b', 'Моё', groupKey: 'g2');
      AppTheme.instance.removeCategory('decorative', 'mascara');
      AppTheme.instance.removeGroup('decorative', 'eyes');
      AppTheme.instance.renameType('care', 'Уход');
      AppTheme.instance.removeType('decorative');
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
      expect(AppTheme.instance.typeName('care'), 'Уход');
      expect(AppTheme.instance.isTypeRemoved('decorative'), isTrue);
      expect(AppTheme.instance.primaryColor.toARGB32(), 0xFFA7E8C4);
      expect(AppTheme.instance.backgroundColor.toARGB32(), 0xFFF3FAF5);
    });
  });
}
