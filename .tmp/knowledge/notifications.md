---
source: pub.dev, GitHub, Official Documentation
topic: flutter local notifications android background tasks
systems: flutter, android, notification packages
created: 2026-05-02
researcher: ResearchAgent
---

# Research: Flutter Local Notifications on Android

## Summary

`flutter_local_notifications` is the dominant Flutter package for local notifications with strong background task support. It handles scheduling, but background work integration requires pairing with `workmanager` or `android_alarm_manager_plus`.

## Pub.dev Stats

### flutter_local_notifications (v21.0.0)
| Metric | Value |
|--------|-------|
| Likes | 7,290 |
| Pub Points | 160/160 (perfect) |
| Downloads | 1.7M weekly |
| Platforms | Android, iOS, Linux, macOS, Windows |
| Flutter SDK | 3.38.1+ required |
| License | BSD-3-Clause |
| GitHub Stars | 2.7k stars, 1.6k forks |

### Workmanager (v0.9.0)
| Metric | Value |
|--------|-------|
| Likes | 2.4k |
| Pub Points | - |
| Downloads | 57.8k weekly |
| License | MIT |

### android_alarm_manager_plus (v5.0.0)
| Metric | Value |
|--------|-------|
| Likes | 606 |
| Downloads | 10.1k weekly |
| License | BSD-3-Clause |

## Package Comparison

| Feature | flutter_local_notifications | workmanager | android_alarm_manager_plus |
|---------|---------------------------|-------------|---------------------------|
| **Primary Purpose** | Display & schedule notifications | Background task execution | Alarm-based callbacks |
| **Schedule Notifications** | ✅ Built-in | ❌ Not included | ❌ Not included |
| **Background Work** | ❌ Limited to foreground | ✅ Full background | ✅ Full background |
| **Wake on Alarm** | ✅ With constraints | ✅ Via constraints | ✅ Direct AlarmManager |
| **Android Only** | ❌ Cross-platform | ❌ Cross-platform | ✅ Android-only |
| **Difficulty** | Medium | Medium | Medium |
| **Maintenance** | Very Active | Active | Active |

### Recommendation

**Use `flutter_local_notifications` for displaying notifications** and **combine with `workmanager`** for reliable background execution:
- `flutter_local_notifications`: Handles notification display, scheduling, channels, actions
- `workmanager`: Handles background Dart code execution when app is closed

## Background Task Integration

### Option 1: flutter_local_notifications alone
- Uses Android's AlarmManager internally for scheduling
- **Problem**: Many OEMs (Xiaomi, Huawei, Samsung) kill background apps
- Scheduled notifications may not fire when app is backgrounded
- Works better on stock Android or with battery optimization disabled

### Option 2: flutter_local_notifications + workmanager
```dart
// Schedule with workmanager, show notification when task runs
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Check for new data
    final hasNewData = await checkServer();
    
    if (hasNewData) {
      // Show notification
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.show(...);
    }
    
    return Future.value(true);
  });
}

// Schedule periodic background check
Workmanager().registerPeriodicTask(
  "backgroundSync",
  "syncTask",
  frequency: const Duration(hours: 1),
);
```

### Option 3: flutter_local_notifications + android_alarm_manager_plus
- More direct AlarmManager access than flutter_local_notifications
- Better for exact timing requirements
- Requires separate notification display logic

## Android-Specific Setup Requirements

### flutter_local_notifications (v21+)

#### Gradle Configuration (android/app/build.gradle)
```groovy
android {
    defaultConfig {
        multiDexEnabled true
    }
    compileSdk 36 // minimum required
    
    compileOptions {
        coreLibraryDesugaringEnabled true  // REQUIRED for scheduled notifications
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

#### AndroidManifest.xml Additions

**For scheduled notifications:**
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<!-- OR for Android 14+: -->
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

<application>
    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
        </intent-filter>
    </receiver>
</application>
```

**For full-screen intent notifications:**
```xml
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

**For foreground services:**
```xml
<service android:name="com.dexterous.flutterlocalnotifications.ForegroundService"
    android:exported="false"
    android:foregroundServiceType="dataSync"/>
```

#### Android 13+ Permission Request
```dart
await FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();
```

### workmanager Setup

#### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### android_alarm_manager_plus Setup

#### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<service android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
    android:permission="android.permission.BIND_JOB_SERVICE"
    android:exported="false"/>
<receiver android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver"
    android:exported="false"/>
<receiver android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
    android:enabled="false"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

## Key Limitations & Gotchas

### Device-Specific Issues
- **Samsung**: Max 500 alarms via AlarmManager
- **Xiaomi/Huawei**: Aggressive background killing - use https://dontkillmyapp.com
- **Android 12+**: SCHEDULE_EXACT_ALARM requires explicit user permission

### Release Build
- Add to `android/app/proguard-rules.pro`:
```proguard
-keepattributes SourceFile,LineNumberTable
-keep class com.dexterous.flutterlocalnotifications.** { *; }
```
- Keep notification icons in `android/app/src/main/res/drawable/`

### Notification Icons
- Place in `android/app/src/main/res/drawable-*` folders
- Required format: white silhouette on transparent background
- Use Android Asset Studio to generate proper icons

## Example: Minimal Setup

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTap,
  );

  // Request permissions on Android 13+
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

void _onNotificationTap(NotificationResponse response) {
  // Handle notification tap - navigate to relevant screen
}

Future<void> showNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'channel_id',
    'Channel Name',
    channelDescription: 'Description',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    'Title',
    'Body',
    details,
  );
}
```

## Links
- [flutter_local_notifications pub.dev](https://pub.dev/packages/flutter_local_notifications)
- [flutter_local_notifications GitHub](https://github.com/MaikuB/flutter_local_notifications)
- [workmanager pub.dev](https://pub.dev/packages/workmanager)
- [android_alarm_manager_plus pub.dev](https://pub.dev/packages/android_alarm_manager_plus)
- [Android notifications guide](https://developer.android.com/guide/topics/ui/notifiers/notification-permission)
- [Don't Kill My App](https://dontkillmyapp.com)
