// End-to-end user flows for opened-product (PAO) tracking, expiry status and
// notifications. Runs on a real device/emulator:
//
//   flutter test integration_test/expiry_flows_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:polochka/main.dart' as app;
import 'package:polochka/models/product.dart';
import 'package:polochka/services/notification_service.dart';
import 'package:polochka/services/storage_factory.dart';

DateTime _dayOffset(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(Duration(days: days));
}

Future<void> _resetStorage() async {
  final storage = createStorageService();
  for (final product in await storage.getAllProducts()) {
    if (product.id != null) await storage.deleteProduct(product.id!);
  }
}

Future<void> _seed(Product product) async {
  await createStorageService().createProduct(product);
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const app.BeautyShelfApp());
  await tester.pumpAndSettle();
}

Future<void> _dismissSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _openAddForm(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  expect(find.text('Добавить продукт'), findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Register the notifications plugin so per-product scheduling doesn't
    // throw during the notification test. Scheduling is best-effort.
    try {
      await NotificationService().initialize();
    } catch (_) {
      // Plugin unavailable on this device - notification test still only
      // asserts persistence, which happens before scheduling.
    }
  });

  setUp(() async {
    await _resetStorage();
  });

  group('opened product (PAO)', () {
    testWidgets('toggling "Вскрыта упаковка" reveals date and PAO fields',
        (tester) async {
      await _pumpApp(tester);
      await _openAddForm(tester);

      expect(find.text('Срок после вскрытия (дней)'), findsNothing);

      await tester.tap(find.text('Вскрыта упаковка'));
      await tester.pumpAndSettle();

      expect(find.text('Дата вскрытия'), findsOneWidget);
      expect(find.text('Срок после вскрытия (дней)'), findsOneWidget);

      // Unchecking hides them again.
      await tester.tap(find.text('Вскрыта упаковка'));
      await tester.pumpAndSettle();
      expect(find.text('Срок после вскрытия (дней)'), findsNothing);
    });

    testWidgets('opened product counts down from the earlier (PAO) limit',
        (tester) async {
      await _pumpApp(tester);
      await _openAddForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Вскрытый крем');
      await tester.tap(find.text('Вскрыта упаковка'));
      await tester.pumpAndSettle();

      // Last TextFormField on an opened product is the PAO field.
      await tester.enterText(find.byType(TextFormField).last, '5');

      await tester.ensureVisible(find.text('Сохранить'));
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await _dismissSnackBar(tester);

      final product = (await createStorageService().getAllProducts())
          .firstWhere((p) => p.name == 'Вскрытый крем');
      expect(product.isOpened, isTrue);
      expect(product.openedDate, isNotNull);
      expect(product.expiryDaysAfterOpen, 5);
      expect(product.daysLeft, 5);

      // The printed date is far (+180d), so the PAO limit is the earlier one.
      // The card renders the status as "Скоро · 5 дн." for a near expiry.
      expect(find.textContaining('5 дн.'), findsOneWidget);
    });
  });

  group('expiry dates and status', () {
    testWidgets('expiry date picker opens from the form', (tester) async {
      await _pumpApp(tester);
      await _openAddForm(tester);

      final expiryField = find.ancestor(
        of: find.text('Годен до'),
        matching: find.byType(InputDecorator),
      );
      await tester.tap(expiryField.first);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      // Cancel is the first TextButton inside the dialog (label is localized).
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('expired product raises the expired banner and sheet',
        (tester) async {
      await _seed(Product(
        name: 'Просроченный',
        type: 'care',
        category: 'face_cream',
        expiryDate: _dayOffset(-1),
      ));
      await _pumpApp(tester);

      expect(find.text('1 просрочено'), findsOneWidget);

      await tester.tap(find.text('1 просрочено'));
      await tester.pumpAndSettle();

      expect(find.text('Истекающие продукты'), findsOneWidget);
      expect(find.text('Просроченный'), findsWidgets);
      expect(find.text('Просрочено'), findsOneWidget);
    });

    testWidgets('product expiring soon raises the warning banner',
        (tester) async {
      await _seed(Product(
        name: 'Скоро',
        type: 'care',
        category: 'serum',
        expiryDate: _dayOffset(3),
      ));
      await _pumpApp(tester);

      expect(find.text('1 скоро истекает'), findsOneWidget);
      expect(find.text('Подробнее →'), findsOneWidget);
    });

    testWidgets('sort by name reorders the list', (tester) async {
      await _seed(Product(
        name: 'Яблоко',
        type: 'care',
        category: 'face_cream',
        expiryDate: _dayOffset(5),
      ));
      await _seed(Product(
        name: 'Абрикос',
        type: 'care',
        category: 'face_cream',
        expiryDate: _dayOffset(10),
      ));
      await _pumpApp(tester);

      // Default sort is expiry asc -> Яблоко (+5) above Абрикос (+10).
      expect(
        tester.getTopLeft(find.text('Яблоко')).dy <
            tester.getTopLeft(find.text('Абрикос')).dy,
        isTrue,
      );

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('По названию'));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Абрикос')).dy <
            tester.getTopLeft(find.text('Яблоко')).dy,
        isTrue,
      );
    });
  });

  group('notifications', () {
    testWidgets('per-product notification days are persisted', (tester) async {
      await _pumpApp(tester);
      await _openAddForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'С напоминанием');
      // Locate the notification field by its label - the positional index is
      // stale now that the brand field sits between name and purpose.
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Уведомить за (дней, оставьте пустым чтобы не уведомлять)',
        ),
        '7',
      );

      await tester.ensureVisible(find.text('Сохранить'));
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await _dismissSnackBar(tester);

      final product = (await createStorageService().getAllProducts())
          .firstWhere((p) => p.name == 'С напоминанием');
      expect(product.notificationDays, 7);
    });

    testWidgets('global threshold control is hidden while disabled',
        (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsOneWidget);

      // The notifications section is below the fold - scroll it into view.
      await tester.scrollUntilVisible(
        find.text('Уведомления о сроке годности'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Уведомления о сроке годности'), findsOneWidget);
      // The "Предупреждать за" row only appears when notifications are on.
      expect(find.text('Предупреждать за'), findsNothing);
    });
  });
}
