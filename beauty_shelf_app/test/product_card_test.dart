import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polochka/models/product.dart';
import 'package:polochka/widgets/product_card.dart';

/// Local midnight of "today" shifted by [days].
DateTime _dayOffset(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(Duration(days: days));
}

Product _p({
  bool opened = false,
  DateTime? openedDate,
  int pao = 30,
  DateTime? expiry,
  int quantity = 1,
  String name = 'Крем',
}) {
  return Product(
    name: name,
    type: 'care',
    category: 'face_cream',
    expiryDate: expiry ?? _dayOffset(100),
    isOpened: opened,
    openedDate: openedDate,
    expiryDaysAfterOpen: pao,
    quantity: quantity,
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  Product product, {
  ValueChanged<int>? onQuantityChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProductCard(
          product: product,
          onEdit: () {},
          onDelete: () {},
          onQuantityChanged: onQuantityChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the effective expiry date when PAO is binding, without a label',
      (tester) async {
    await _pumpCard(
      tester,
      _p(opened: true, openedDate: _dayOffset(-10), pao: 12, expiry: _dayOffset(500)),
    );
    expect(find.textContaining('до '), findsOneWidget);
    expect(find.textContaining('после вскрытия'), findsNothing);
    expect(find.textContaining('срок производителя'), findsNothing);
  });

  testWidgets('shows the effective expiry date when the printed date is binding, without a label',
      (tester) async {
    await _pumpCard(
      tester,
      _p(opened: true, openedDate: _dayOffset(-5), pao: 365, expiry: _dayOffset(10)),
    );
    expect(find.textContaining('до '), findsOneWidget);
    expect(find.textContaining('после вскрытия'), findsNothing);
    expect(find.textContaining('срок производителя'), findsNothing);
  });

  testWidgets('shows no binding-limit label when not opened', (tester) async {
    await _pumpCard(tester, _p(expiry: _dayOffset(50)));
    expect(find.textContaining('после вскрытия'), findsNothing);
    expect(find.textContaining('срок производителя'), findsNothing);
  });

  testWidgets('quantity stepper does not squeeze the text lines', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const longName = 'Увлажняющий ночной крем для лица';

    // Baseline: no callback -> the stepper is hidden.
    await _pumpCard(tester, _p(quantity: 3, name: longName));
    final widthWithout = tester.getSize(find.text(longName)).width;
    expect(find.text('3'), findsNothing);

    // With the stepper pinned to the bottom-right corner.
    await _pumpCard(
      tester,
      _p(quantity: 3, name: longName),
      onQuantityChanged: (_) {},
    );

    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The text keeps the exact same width: the stepper overlays the corner
    // instead of widening the controls column.
    final widthWith = tester.getSize(find.text(longName)).width;
    expect(widthWith, widthWithout);
  });

  testWidgets('shows an opened-package indicator only when opened', (tester) async {
    await _pumpCard(tester, _p(opened: false));
    expect(find.byIcon(Icons.lock_open), findsNothing);

    await _pumpCard(tester, _p(opened: true, openedDate: _dayOffset(-10)));
    expect(find.byIcon(Icons.lock_open), findsOneWidget);
  });
}
