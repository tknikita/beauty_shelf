// On-device verification for the two settings fixes:
//   1. choosing a colour preset actually changes the scaffold background
//   2. a built-in category can be deleted and stays deleted
//
// Run on a real device/emulator:
//
//   flutter test integration_test/theme_categories_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:polochka/main.dart' as app;
import 'package:polochka/screens/settings_screen.dart';
import 'package:polochka/services/notification_service.dart';
import 'package:polochka/theme/app_theme.dart';

const _defaultPrimary = Color(0xFFE8B4BC);
const _defaultBackground = Color(0xFFFDF9FA);

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    try {
      await NotificationService().initialize();
    } catch (_) {
      // Notifications are irrelevant for these tests.
    }
  });

  setUp(() async {
    // Isolate preferences so the tests neither depend on nor pollute the
    // emulator's real app data.
    SharedPreferences.setMockInitialValues({});
    AppTheme.instance.resetCategoriesForTest();
    AppTheme.instance.applyLoadedDarkMode(false);
    AppTheme.instance.applyPreset(_defaultPrimary, _defaultBackground);
  });

  testWidgets('choosing a preset changes the background', (tester) async {
    await _openSettings(tester);

    // Before: default background.
    expect(AppTheme.instance.backgroundColor.toARGB32(), _defaultBackground.toARGB32());

    // Tap the "Лаванда" preset (bg 0xFFF5F3FA).
    await tester.tap(find.text('Лаванда'));
    await tester.pumpAndSettle();

    // Model updated...
    expect(AppTheme.instance.backgroundColor.toARGB32(), 0xFFF5F3FA);

    // ...and the rendered settings screen actually uses it.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor?.toARGB32(), 0xFFF5F3FA);

    // Let the "Применён" snackbar auto-dismiss so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a built-in category can be deleted', (tester) async {
    await _openSettings(tester);

    // Expand the "Уходовая" (care) list.
    final scrollable = _settingsScrollable();
    await tester.scrollUntilVisible(find.text('Уходовая'), 300, scrollable: scrollable);
    await tester.tap(find.text('Уходовая'));
    await tester.pumpAndSettle();

    // The built-in "cream" row exists and is reachable.
    final creamRow = find.byKey(const ValueKey('care_cream'));
    await tester.scrollUntilVisible(creamRow, 300, scrollable: scrollable);
    expect(creamRow, findsOneWidget);
    expect(AppTheme.instance.getCategoriesByType('care').containsKey('cream'), isTrue);

    // Delete it.
    await tester.tap(
      find.descendant(of: creamRow, matching: find.byIcon(Icons.delete_outline)),
    );
    await tester.pumpAndSettle();

    // Gone from both the model and the UI.
    expect(AppTheme.instance.getCategoriesByType('care').containsKey('cream'), isFalse);
    expect(find.byKey(const ValueKey('care_cream')), findsNothing);
  });
}
