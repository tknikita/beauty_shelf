import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:polochka/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('notifications are disabled by default', () async {
    expect(await NotificationService().areNotificationsEnabled(), isFalse);
  });

  test('notification threshold defaults to 7 days', () async {
    expect(await NotificationService().getNotificationDays(), 7);
  });

  test('threshold can be changed and is persisted', () async {
    final service = NotificationService();
    // While notifications are disabled, scheduling exits early and does not
    // touch the platform plugin, so this is safe in a unit test.
    await service.setNotificationDays(14);

    expect(await service.getNotificationDays(), 14);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('notification_days'), 14);
  });

  test('saving the threshold when disabled does not throw', () async {
    await expectLater(NotificationService().setNotificationDays(3), completes);
    expect(await NotificationService().getNotificationDays(), 3);
  });
}
