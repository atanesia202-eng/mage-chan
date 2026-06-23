import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mage_chan/services/social_notification_service.dart';

class PermissionManager {
  /// Request all necessary permissions for Mage-chan to function
  static Future<void> requestAllPermissions(BuildContext context) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    final phoneStatus = await Permission.phone.status;
    if (!phoneStatus.isGranted) {
      await Permission.phone.request();
    }

    await _ensureNotificationListenerAccess(context);
  }

  static Future<void> _ensureNotificationListenerAccess(BuildContext context) async {
    final hasAccess = await NotificationsListener.hasPermission ?? false;
    if (hasAccess) {
      await SocialNotificationService().startListening();
      return;
    }

    if (!context.mounted) return;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เปิดสิทธิ์ดักจับแจ้งเตือน'),
        content: const Text(
          'เพื่อให้ Mage-chan ดักจับข้อความจาก Messenger, LINE, IG ได้\n'
          'กรุณาเปิด "การเข้าถึงการแจ้งเตือน" สำหรับ Mage-chan ใน Settings',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ไว้ทีหลัง'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ไปตั้งค่า'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await NotificationsListener.openPermissionSettings();
    }
  }

  static Future<bool> isNotificationGranted() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  static Future<bool> isNotificationListenerGranted() async {
    return await NotificationsListener.hasPermission ?? false;
  }
}
