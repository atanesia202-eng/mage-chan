import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:mage_chan/main.dart';
import 'package:mage_chan/features/reminder/presentation/screens/reminder_alert_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelGroupKey: 'mage_chan_group',
          channelKey: 'mage_chan_alerts',
          channelName: 'Mage-chan Alerts',
          channelDescription:
              'Notification channel for Mage-chan reminders and alerts',
          defaultColor: const Color(0xFFFFB6C1),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          criticalAlerts: true,
          enableVibration: true,
          locked: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'mage_chan_group',
          channelGroupName: 'Mage-chan Group',
        ),
      ],
      debug: true,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Here we can fire an event to our EventBus to wake up the app or trigger a Voice response!
    debugPrint('Notification action received: ${receivedAction.payload}');

    final payload = receivedAction.payload;

    // Check if it's our boss alert / exact-time alert payload
    if (payload?['type'] == 'boss_alert') {
      final title = payload?['title'] ?? 'แจ้งเตือน';
      final time = payload?['time'] ?? '';
      final message = 'ถึงเวลาแล้วเจ้าคะ';

      navigatorKey.currentState?.push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, _, __) =>
              ReminderAlertScreen(
                title: title,
                time: time,
                message: message,
              ),
        ),
      );
    }
  }

  /// Helper method to show a simple notification (used for pre-alerts)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'mage_chan_alerts',
        title: title,
        body: body,
        payload: payload,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  /// Trigger a full-screen alarm notification (used for exact-time alerts)
  Future<void> showFullScreenAlarm({
    required int id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    final mergedPayload = payload ?? {};
    mergedPayload['type'] = 'boss_alert';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'mage_chan_alerts',
        title: title,
        body: body,
        payload: mergedPayload,
        category: NotificationCategory.Alarm,
        fullScreenIntent: true,
        wakeUpScreen: true,
        autoDismissible: false,
      ),
    );

    // We rely on fullScreenIntent from awesome_notifications instead of flutter_overlay_window
  }
}
