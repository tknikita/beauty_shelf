import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polochka/models/product.dart';
import 'package:polochka/widgets/product_form.dart';

Future<void> _pumpForm(
  WidgetTester tester,
  Product product,
  void Function(Product) onSave,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProductForm(product: product, onSave: onSave),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Product _mask() => Product(
      id: 1,
      name: 'Гидрогелевая маска',
      type: 'care',
      category: 'mask',
      expiryDate: DateTime(2027, 1, 1),
    );

void main() {
  testWidgets('changing type keeps a valid category', (tester) async {
    Product? saved;
    await _pumpForm(tester, _mask(), (p) => saved = p);

    // Re-select the same "Тип" — this used to silently reset the category.
    final typeDropdown = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(typeDropdown);
    await tester.tap(typeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Уходовая').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.category, 'mask');
  });

  testWidgets('an unknown/deleted category is preserved on save', (tester) async {
    Product? saved;
    final product = Product(
      id: 2,
      name: 'X',
      type: 'care',
      category: 'custom_999',
      expiryDate: DateTime(2027, 1, 1),
    );
    await _pumpForm(tester, product, (p) => saved = p);

    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.category, 'custom_999');
  });
}
