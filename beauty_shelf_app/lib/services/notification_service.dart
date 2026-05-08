import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/product.dart';
import 'storage_io.dart';

const String _notificationChannelId = 'expiring_products';
const String _notificationChannelName = 'Срок годности';
const String _notificationChannelDesc = 'Уведомления о сроке годности продуктов';

/// Service for managing expiry notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Schedule daily check (may fail if exact alarms not permitted)
    try {
      await _scheduleDailyCheck();
    } catch (e) {
      debugPrint('Failed to schedule notifications: $e');
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await _scheduleDailyCheck();
    } else {
      await cancelAllNotifications();
    }
  }

  /// Get notification days threshold
  Future<int> getNotificationDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_days') ?? 7;
  }

  /// Set notification days threshold
  Future<void> setNotificationDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_days', days);
    await _scheduleDailyCheck();
  }

  /// Schedule daily check for expiring products
  Future<void> _scheduleDailyCheck() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    // Cancel existing scheduled notification
    await _notifications.cancel(999);

    // Use explicit timezone instead of tz.local which may be null on some devices
    final location = tz.getLocation('Europe/Moscow');
    
    // Schedule for 9 AM tomorrow
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, 9);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      999,
      '⏰ Проверка срока годности',
      'Проверяем продукты...',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Check expiring products and show notification
  Future<void> checkAndNotifyExpiringProducts() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final days = await getNotificationDays();
    final storage = MobileStorageService();
    final expiringProducts = await storage.getExpiringProducts(days);

    if (expiringProducts.isNotEmpty) {
      await _showExpiringNotification(expiringProducts, days);
    }
  }

  /// Show notification for expiring products
  Future<void> _showExpiringNotification(List<Product> products, int days) async {
    final count = products.length;
    final message = count == 1
        ? '${products.first.name} истекает через $days дн.'
        : '$count продуктов истекают через $days дн. или раньше';

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notifications.show(
      0,
      '⏰ Срок годности',
      message,
      details,
      payload: 'expiring_products',
    );
  }

  /// Show immediate notification for a single product
  Future<void> showProductExpiryNotification(Product product) async {
    final days = product.daysLeft;
    String message;

    if (days < 0) {
      message = '${product.name} просрочен';
    } else if (days == 0) {
      message = '${product.name} истекает сегодня!';
    } else {
      message = '${product.name} истекает через $days дн.';
    }

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      product.id ?? product.hashCode,
      '⏰ Срок годности',
      message,
      details,
      payload: 'product_${product.id}',
    );
  }

  /// Schedule a notification for a specific product
  Future<void> scheduleProductNotification(Product product) async {
    if (product.id == null || product.notificationDays == null) return;

    final daysBeforeExpiry = product.notificationDays!;
    final effectiveDate = product.effectiveExpiryDate;
    
    // Guard against null or invalid date
    if (effectiveDate == null) return;
    
    final notificationDate = effectiveDate.subtract(
      Duration(days: daysBeforeExpiry),
    );

    // Don't schedule if the notification date is in the past (before tomorrow)
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowMidnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    if (notificationDate.isBefore(tomorrowMidnight)) return;

    final notificationId = _getNotificationId(product.id!);

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    // Use explicit timezone instead of tz.local which may be null
    final location = tz.getLocation('Europe/Moscow');
    
    // Schedule for 9 AM on the notification date
    final scheduledDate = tz.TZDateTime(
      location,
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      9,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '⏰ Срок годности',
      '${product.name} истекает через $daysBeforeExpiry дн.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'product_${product.id}',
    );
  }

  /// Cancel notification for a specific product
  Future<void> cancelProductNotification(int productId) async {
    try {
      await _notifications.cancel(_getNotificationId(productId));
    } catch (e) {
      debugPrint('Failed to cancel notification $productId: $e');
    }
  }

  int _getNotificationId(int productId) {
    // Use a range of IDs for product notifications (1000-9999)
    return 1000 + (productId % 9000);
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
