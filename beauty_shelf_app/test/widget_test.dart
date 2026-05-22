import 'package:flutter_test/flutter_test.dart';
import 'package:polochka/main.dart';

void main() {
  testWidgets('App loads with correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const BeautyShelfApp());
    await tester.pump();
    expect(find.text('Полочка'), findsWidgets);
  });
}
