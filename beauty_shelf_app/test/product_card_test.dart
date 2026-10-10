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
}) {
  return Product(
    name: 'Крем',
    type: 'care',
    category: 'face_cream',
    expiryDate: expiry ?? _dayOffset(100),
    isOpened: opened,
    openedDate: openedDate,
    expiryDaysAfterOpen: pao,
  );
}

Future<void> _pumpCard(WidgetTester tester, Product product) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProductCard(
          product: product,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the after-opening limit when PAO is binding', (tester) async {
    await _pumpCard(
      tester,
      _p(opened: true, openedDate: _dayOffset(-10), pao: 12, expiry: _dayOffset(500)),
    );
    expect(find.textContaining('после вскрытия'), findsOneWidget);
  });

  testWidgets('shows the manufacturer limit when the printed date is binding', (tester) async {
    await _pumpCard(
      tester,
      _p(opened: true, openedDate: _dayOffset(-5), pao: 365, expiry: _dayOffset(10)),
    );
    expect(find.textContaining('срок производителя'), findsOneWidget);
    expect(find.textContaining('после вскрытия'), findsNothing);
  });

  testWidgets('shows no binding-limit label when not opened', (tester) async {
    await _pumpCard(tester, _p(expiry: _dayOffset(50)));
    expect(find.textContaining('после вскрытия'), findsNothing);
    expect(find.textContaining('срок производителя'), findsNothing);
  });
}
