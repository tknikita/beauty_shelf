// End-to-end user-flow tests that run on a real device/emulator.
//
// Run with:
//   flutter test integration_test/app_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:polochka/main.dart' as app;
import 'package:polochka/services/storage_factory.dart';
import 'package:polochka/theme/app_theme.dart';

/// Remove all products so each scenario starts from a clean shelf.
Future<void> _resetStorage() async {
  final storage = createStorageService();
  final products = await storage.getAllProducts();
  for (final product in products) {
    if (product.id != null) {
      await storage.deleteProduct(product.id!);
    }
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const app.BeautyShelfApp());
  await tester.pumpAndSettle();
}

/// Let transient SnackBars disappear so they don't intercept later taps.
Future<void> _dismissSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Full "add product" flow through the form UI.
Future<void> _addProductViaUi(
  WidgetTester tester,
  String name, {
  String? typeLabel,
}) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  expect(find.text('Добавить продукт'), findsOneWidget);

  await tester.enterText(find.byType(TextFormField).first, name);

  if (typeLabel != null) {
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(typeLabel).last);
    await tester.pumpAndSettle();
  }

  await tester.ensureVisible(find.text('Сохранить'));
  await tester.tap(find.text('Сохранить'));
  await tester.pumpAndSettle();
  await _dismissSnackBar(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _resetStorage();
  });

  testWidgets('01 launch shows the empty shelf', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Полочка'), findsWidgets);
    expect(find.text('Полка пуста'), findsOneWidget);
  });

  testWidgets('02 add product appears in list and persists', (tester) async {
    await _pumpApp(tester);
    await _addProductViaUi(tester, 'Крем Тестовый');

    expect(find.text('Крем Тестовый'), findsOneWidget);

    final storage = createStorageService();
    final all = await storage.getAllProducts();
    expect(all.any((p) => p.name == 'Крем Тестовый'), isTrue);
  });

  testWidgets('03 search filters the list', (tester) async {
    await _pumpApp(tester);
    await _addProductViaUi(tester, 'Сыворотка A');
    await _addProductViaUi(tester, 'Крем B');

    expect(find.text('Сыворотка A'), findsOneWidget);
    expect(find.text('Крем B'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Сыворотка');
    await tester.pumpAndSettle();

    expect(find.text('Сыворотка A'), findsOneWidget);
    expect(find.text('Крем B'), findsNothing);

    // Clearing the query restores the full list.
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    expect(find.text('Крем B'), findsOneWidget);
  });

  testWidgets('04 edit renames the product', (tester) async {
    await _pumpApp(tester);
    await _addProductViaUi(tester, 'Старое Имя');

    await tester.tap(find.text('Старое Имя'));
    await tester.pumpAndSettle();
    expect(find.text('Изменить продукт'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Новое Имя');
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await _dismissSnackBar(tester);

    expect(find.text('Новое Имя'), findsOneWidget);
    expect(find.text('Старое Имя'), findsNothing);
  });

  testWidgets('05 delete removes the product', (tester) async {
    await _pumpApp(tester);
    await _addProductViaUi(tester, 'Удаляемый');

    expect(find.text('Удаляемый'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Удалить продукт?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    await _dismissSnackBar(tester);

    expect(find.text('Удаляемый'), findsNothing);
    expect(find.text('Полка пуста'), findsOneWidget);
  });

  testWidgets('06 type filter shows only the matching type', (tester) async {
    await _pumpApp(tester);
    await _addProductViaUi(tester, 'Крем Уход');
    await _addProductViaUi(tester, 'Помада Декор', typeLabel: 'Декоративная');

    expect(find.text('Крем Уход'), findsOneWidget);
    expect(find.text('Помада Декор'), findsOneWidget);

    // Open the first dropdown (type filter) and pick "Уход".
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Уход').last);
    await tester.pumpAndSettle();

    expect(find.text('Крем Уход'), findsOneWidget);
    expect(find.text('Помада Декор'), findsNothing);
  });

  testWidgets('07 settings toggles dark theme', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);

    final wasDark = AppTheme.instance.isDarkMode;
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(AppTheme.instance.isDarkMode, isNot(wasDark));

    // Restore original state.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(AppTheme.instance.isDarkMode, wasDark);
  });
}
