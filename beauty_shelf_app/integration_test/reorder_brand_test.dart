// On-device tests for manual card reordering and brand search.
//
//   flutter test integration_test/reorder_brand_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:polochka/main.dart' as app;
import 'package:polochka/models/product.dart';
import 'package:polochka/services/storage_factory.dart';
import 'package:polochka/utils/sorting.dart';

Product _p(String name, int position, String? brand) => Product(
      name: name,
      type: 'care',
      category: 'face_cream',
      expiryDate: DateTime(2027, 1, 1),
      brand: brand,
      position: position,
    );

Future<void> _seed() async {
  final storage = createStorageService();
  for (final p in await storage.getAllProducts()) {
    if (p.id != null) await storage.deleteProduct(p.id!);
  }
  await storage.createProduct(_p('Alpha', 1, 'CeraVe'));
  await storage.createProduct(_p('Beta', 2, 'Dior'));
  await storage.createProduct(_p('Gamma', 3, 'Nivea'));
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const app.BeautyShelfApp());
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _seed();
  });

  testWidgets('manual sort mode reorders cards and persists', (tester) async {
    await _pumpApp(tester);

    // Switch to manual order via the sort menu.
    await tester.tap(find.byType(PopupMenuButton<SortField>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Вручную').last);
    await tester.pumpAndSettle();

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder(0, 2); // move the first card down one slot
    await tester.pumpAndSettle();

    final ordered = await createStorageService().getAllProducts();
    ordered.sort((a, b) => a.position.compareTo(b.position));
    expect(ordered.map((p) => p.name).toList(), ['Beta', 'Alpha', 'Gamma']);
  });

  testWidgets('search matches brand, not only name', (tester) async {
    await _pumpApp(tester);

    await tester.enterText(find.byType(TextField).first, 'CeraVe');
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(find.text('Gamma'), findsNothing);
  });
}
