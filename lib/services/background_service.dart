import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reminder_model.dart';
import '../models/finance_model.dart';
import '../models/social_notification_model.dart';
import '../models/fixed_expense_model.dart';
import '../services/notification_service.dart';
import '../services/social_notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

class BackgroundServiceManager {
  static final BackgroundServiceManager _instance = BackgroundServiceManager._internal();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._internal();

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'mage_chan_alerts', // Must match the one in AwesomeNotifications
        initialNotificationTitle: 'Mage-chan is Active',
        initialNotificationContent: 'Monitoring reminders and events...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static void start() {
    FlutterBackgroundService().startService();
  }

  static void stop() {
    FlutterBackgroundService().invoke("stopService");
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Isar in background isolate
  Isar? db;
  try {
    final dir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [
        ReminderModelSchema,
        FixedIncomeModelSchema,
        TransactionModelSchema,
        SocialNotificationModelSchema,
        FixedExpenseModelSchema,
      ],
      directory: dir.path,
    );
  } catch (e) {
    // DB might already be open in main isolate, try to get the instance
    try {
      db = Isar.getInstance();
    } catch (_) {
      debugPrint('Failed to open Isar in background: $e');
    }
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // HACK: Intercept the notification listener method channel in the background isolate
  // because flutter_background_service overwrites the FlutterEngineCache!
  const bgChannel = MethodChannel('flutter_notification_listener/bg_method');
  bgChannel.setMethodCallHandler((call) async {
    debugPrint('[SocialNotif:HackBG] 🚨 INTERCEPTED METHOD in Background Engine: ${call.method}');
    if (call.method == 'sink_event') {
      try {
        final args = call.arguments as List<dynamic>;
        final map = args[1] as Map<dynamic, dynamic>;
        final event = NotificationEvent.fromMap(map);
        
        final data = SocialNotificationService.extractDataFromEvent(event);
        if (data != null && db != null) {
          final model = SocialNotificationModel()
            ..appName = data['appName']!
            ..packageName = data['packageName']!
            ..title = data['title']!
            ..content = data['content']!
            ..timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(data['timestamp']!));
            
          await db!.writeTxn(() async {
            await db!.socialNotificationModels.put(model);
          });
          debugPrint('[SocialNotif:HackBG] ✅ Saved notification from background isolate!');
        }
      } catch (e) {
        debugPrint('[SocialNotif:HackBG] ❌ Error parsing event: $e');
      }
    }
  });

  // Track which notifications we've already sent to avoid duplicates
  // Key: "reminder_id_time_type" (type = "pre" or "exact")
  final Set<String> sentNotifications = {};

  // Clear sent notifications at midnight
  String lastDate = _getCurrentDateString();

  // Background Loop - every minute
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    debugPrint('Mage-chan background loop heartbeat: ${DateTime.now()}');

    // Reset sent notifications at midnight
    final currentDate = _getCurrentDateString();
    if (currentDate != lastDate) {
      sentNotifications.clear();
      lastDate = currentDate;
    }

    if (db == null) return;

    try {
      final reminders = await db.reminderModels.where().findAll();
      final now = DateTime.now();

      for (final reminder in reminders) {
        // Check if this reminder should fire today
        if (!_shouldFireToday(reminder, now)) continue;

        for (final timeString in reminder.allTimes) {
          final timeParts = timeString.split(':');
          if (timeParts.length != 2) continue;

          final targetHour = int.tryParse(timeParts[0]) ?? 0;
          final targetMinute = int.tryParse(timeParts[1]) ?? 0;

          final currentHour = now.hour;
          final currentMinute = now.minute;

          // Calculate minutes until target
          int targetTotalMinutes = targetHour * 60 + targetMinute;
          int currentTotalMinutes = currentHour * 60 + currentMinute;

          // Pre-alert: 10 minutes before
          final preAlertKey = '${reminder.id}_${timeString}_pre_$currentDate';
          if (currentTotalMinutes == targetTotalMinutes - 10 && !sentNotifications.contains(preAlertKey)) {
            sentNotifications.add(preAlertKey);
            
            final notifService = NotificationService();
            await notifService.showNotification(
              // Unique ID per reminder and time using hash code to avoid collision
              id: '${reminder.id}${timeString}pre'.hashCode.abs(),
              title: '📋 ${reminder.title}',
              body: '⏰ เวลานัดหมาย: $timeString น.\nโปรดเตรียมพร้อมนะคะนายท่านใกล้จะถึงเวลานัดแล้วเจ้าคะ',
              payload: {
                'type': 'pre_alert',
                'title': reminder.title,
                'time': timeString,
              },
            );
            debugPrint('Pre-alert sent for: ${reminder.title} at $timeString');
          }

          // Exact time alert: full-screen alarm
          final exactKey = '${reminder.id}_${timeString}_exact_$currentDate';
          if (currentTotalMinutes == targetTotalMinutes && !sentNotifications.contains(exactKey)) {
            sentNotifications.add(exactKey);
            
            final notifService = NotificationService();
            await notifService.showFullScreenAlarm(
              // Unique ID per reminder and time
              id: '${reminder.id}${timeString}exact'.hashCode.abs(),
              title: '📋 ${reminder.title}',
              body: '⏰ $timeString น.\nถึงเวลาแล้วเจ้าคะ',
              payload: {
                'title': reminder.title,
                'time': timeString,
              },
            );
            debugPrint('Exact-time alert sent for: ${reminder.title} at $timeString');
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking reminders: $e');
    }
  });
}

/// Check if a reminder should fire today based on its repeatType
bool _shouldFireToday(ReminderModel reminder, DateTime now) {
  switch (reminder.repeatType) {
    case 'daily':
      return true;

    case 'custom':
      if (reminder.customDaysList == null || reminder.customDaysList!.isEmpty) {
        return false;
      }
      // customDaysList uses 1=Monday, 7=Sunday (same as DateTime.weekday)
      return reminder.customDaysList!.contains(now.weekday);

    case 'specific_date':
      if (reminder.specificDate == null) return false;
      final specificDate = DateTime.fromMillisecondsSinceEpoch(reminder.specificDate!);
      return now.year == specificDate.year &&
             now.month == specificDate.month &&
             now.day == specificDate.day;

    default:
      return false;
  }
}

String _getCurrentDateString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
