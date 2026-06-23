import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../database/isar_service.dart';

/// Provider: จำนวน Reminder ทั้งหมดที่บันทึกไว้ (ยังไม่ mark complete)
final activeRemindersCountProvider = StreamProvider<int>((ref) {
  return IsarService.watchReminders().map((reminders) {
    return reminders.where((r) => !r.isCompleted).length;
  });
});

/// Provider: จำนวน Social Notification ที่ได้รับวันนี้
final todayNotificationsCountProvider = StreamProvider<int>((ref) {
  return IsarService.watchSocialNotifications().map((notifications) {
    final now = DateTime.now();
    return notifications.where((n) =>
      n.timestamp.year == now.year &&
      n.timestamp.month == now.month &&
      n.timestamp.day == now.day
    ).length;
  });
});

/// Provider: จำนวนสายโทรเข้าวันนี้ (ใช้ call_log package, Android only)
final todayCallsCountProvider = StreamProvider<int>((ref) {
  // Use a periodic timer to refresh call log data every 60 seconds
  final controller = StreamController<int>();

  Future<int> fetchCallCount() async {
    try {
      final status = await Permission.phone.status;
      if (!status.isGranted) return 0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final Iterable<CallLogEntry> entries = await CallLog.query(
        dateFrom: startOfDay.millisecondsSinceEpoch,
        dateTo: now.millisecondsSinceEpoch,
      );

      return entries.length;
    } catch (e) {
      return 0;
    }
  }

  // Fetch immediately
  fetchCallCount().then((count) {
    if (!controller.isClosed) controller.add(count);
  });

  // Then refresh every 60 seconds
  final timer = Timer.periodic(const Duration(seconds: 60), (_) async {
    final count = await fetchCallCount();
    if (!controller.isClosed) controller.add(count);
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
