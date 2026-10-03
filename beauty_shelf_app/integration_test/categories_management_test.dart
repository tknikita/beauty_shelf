// On-device tests for category/type management:
// groups (subcategories) and product types can be renamed / hidden, and the
// category list can switch between alphabetical and manual (drag) order.
//
//   flutter test integration_test/categories_management_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:polochka/main.dart' as app;
import 'package:polochka/screens/settings_screen.dart';
import 'package:polochka/services/notification_service.dart';
import 'package:polochka/theme/app_theme.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.pumpWidget(const app.BeautyShelfApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  expect(find.text('Настройки'), findsOneWidget);
}

Finder _settingsScrollable() => find
    .descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable))
    .first;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: _settingsScrollable());
}

Future<void> _expandCategoryTab(WidgetTester tester, String label) async {
  await _scrollTo(tester, find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _groupMenu(String groupName) {
  final header = find.ancestor(of: find.text(groupName), matching: find.byType(Row)).first;
  return find.descendant(of: header, matching: find.byType(PopupMenuButton<String>));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    try {
      await NotificationService().initialize();
    } catch (_) {
      // Notifications are irrelevant here.
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTheme.instance.resetCategoriesForTest();
  });

  testWidgets('renames a built-in group', (tester) async {
    await _openSettings(tester);
    await _expandCategoryTab(tester, 'Уходовая');

    await _scrollTo(tester, find.text('Кремы'));
    await tester.tap(_groupMenu('Кремы'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переименовать').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Кремы NEW');
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();

    expect(AppTheme.instance.getGroupsByType('care')['creams'], 'Кремы NEW');
    expect(find.text('Кремы NEW'), findsOneWidget);
  });

  testWidgets('hides a built-in group', (tester) async {
    await _openSettings(tester);
    await _expandCategoryTab(tester, 'Уходовая');

    await _scrollTo(tester, find.text('Кремы'));
    await tester.tap(_groupMenu('Кремы'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();

    expect(
      AppTheme.instance.getGroupsByType('care').containsKey('creams'),
      isFalse,
    );
    expect(find.text('Кремы'), findsNothing);
  });

  testWidgets('renames a product type', (tester) async {
    await _openSettings(tester);
    await _scrollTo(tester, find.text('Типы'));
    await tester.tap(find.text('Типы'));
    await tester.pumpAndSettle();

    final tile =
        find.ancestor(of: find.text('Уходовая'), matching: find.byType(ListTile)).first;
    await tester.tap(find.descendant(of: tile, matching: find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Кожа');
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();

    expect(AppTheme.instance.typeName('care'), 'Кожа');
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
  });

  testWidgets('hides and restores a product type', (tester) async {
    await _openSettings(tester);
    await _scrollTo(tester, find.text('Типы'));
    await tester.tap(find.text('Типы'));
    await tester.pumpAndSettle();

    final tile = find
        .ancestor(of: find.text('Декоративная'), matching: find.byType(ListTile))
        .first;
    await tester.tap(
      find.descendant(of: tile, matching: find.byIcon(Icons.delete_outline)),
    );
    await tester.pumpAndSettle();
    expect(AppTheme.instance.isTypeRemoved('decorative'), isTrue);

    final hiddenTile = find
        .ancestor(of: find.text('Декоративная'), matching: find.byType(ListTile))
        .first;
    await tester.tap(
      find.descendant(of: hiddenTile, matching: find.byIcon(Icons.restore)),
    );
    await tester.pumpAndSettle();
    expect(AppTheme.instance.isTypeRemoved('decorative'), isFalse);

    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
  });

  testWidgets('manual sort mode reorders leaves by drag', (tester) async {
    await _openSettings(tester);
    await _expandCategoryTab(tester, 'Уходовая');

    // Switch the care tab to manual order.
    await tester.tap(find.byIcon(Icons.sort_by_alpha).first);
    await tester.pumpAndSettle();
    expect(AppTheme.instance.isManualSort('care'), isTrue);
    expect(find.byIcon(Icons.drag_indicator), findsWidgets);

    final before = AppTheme.instance
        .getCategoryTree('care')
        .firstWhere((g) => g.key == 'creams')
        .leaves
        .keys
        .toList();

    final handle = find
        .descendant(
          of: find.byKey(const ValueKey('leaf_care_cream')),
          matching: find.byIcon(Icons.drag_indicator),
        )
        .first;
    await _scrollTo(tester, handle);

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.moveBy(const Offset(0, 70));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();

    final after = AppTheme.instance
        .getCategoryTree('care')
        .firstWhere((g) => g.key == 'creams')
        .leaves
        .keys
        .toList();
    expect(after, isNot(equals(before)));
  });
}
