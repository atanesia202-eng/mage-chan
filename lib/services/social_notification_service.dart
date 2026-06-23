import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../database/isar_service.dart';
import '../models/social_notification_model.dart';

const _listenerPortName = 'mage_chan_social_listener';

/// Service that listens for incoming notifications from social media apps
/// and saves them to the local Isar database.
class SocialNotificationService {
  static final SocialNotificationService _instance = SocialNotificationService._internal();
  factory SocialNotificationService() => _instance;
  SocialNotificationService._internal();

  ReceivePort? _receivePort;

  /// Package names of social media apps we want to track
  static const Set<String> trackedPackages = {
    'jp.naver.line.android',
    'com.facebook.orca',
    'com.facebook.katana',
    'com.instagram.android',
    'com.whatsapp',
    'com.twitter.android',
    'org.telegram.messenger',
  };

  static const Map<String, String> appNames = {
    'jp.naver.line.android': 'line',
    'com.facebook.orca': 'messenger',
    'com.facebook.katana': 'facebook',
    'com.instagram.android': 'instagram',
    'com.whatsapp': 'whatsapp',
    'com.twitter.android': 'twitter',
    'org.telegram.messenger': 'telegram',
  };

  /// Initialize listener and wire events into the main isolate (where Isar is open).
  Future<void> initialize() async {
    try {
      _setupMainIsolateReceiver();
      await NotificationsListener.initialize(
        callbackHandle: _backgroundNotificationCallback,
      );
    } catch (e) {
      debugPrint('SocialNotificationService init error: $e');
    }
  }

  void _setupMainIsolateReceiver() {
    _receivePort?.close();
    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(_listenerPortName);
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      _listenerPortName,
    );
    _receivePort!.listen((message) {
      if (message is NotificationEvent) {
        handleNotificationEvent(message);
      }
    });
  }

  /// Start or restart the Android notification listener service.
  Future<bool> startListening() async {
    try {
      final hasPermission = await NotificationsListener.hasPermission ?? false;
      if (!hasPermission) {
        debugPrint('SocialNotificationService: no notification listener permission');
        return false;
      }

      final isRunning = await NotificationsListener.isRunning ?? false;
      if (!isRunning) {
        await NotificationsListener.startService(
          foreground: true,
          title: 'Mage-chan Notification Listener',
          description: 'กำลังดักจับแจ้งเตือนเพื่อนายท่าน...',
        );
      }

      debugPrint('SocialNotificationService: listening active');
      return true;
    } catch (e) {
      debugPrint('SocialNotificationService start error: $e');
      return false;
    }
  }

  /// Open system settings so the user can grant notification access.
  Future<void> requestPermission() async {
    await NotificationsListener.openPermissionSettings();
  }

  Future<bool> hasPermission() async {
    return await NotificationsListener.hasPermission ?? false;
  }

  /// Process a notification in the main isolate and persist it.
  static Future<void> handleNotificationEvent(NotificationEvent event) async {
    try {
      final packageName = event.packageName ?? '';
      if (!trackedPackages.contains(packageName)) return;

      // Skip group summary rows that carry no message body.
      if (event.isGroup == true) {
        final preview = _extractContent(event);
        if (preview.isEmpty) return;
      }

      var title = _extractTitle(event);
      var content = _extractContent(event);

      if (title.isEmpty && content.isEmpty) return;
      if (content.isEmpty) content = title;

      final appName = appNames[packageName] ?? packageName;

      final notif = SocialNotificationModel()
        ..appName = appName
        ..packageName = packageName
        ..title = title
        ..content = content
        ..timestamp = DateTime.now();

      await IsarService.saveSocialNotification(notif);
      debugPrint('Saved notification from $appName: $title — $content');
    } catch (e) {
      debugPrint('Error handling notification: $e');
    }
  }

  static String _extractTitle(NotificationEvent event) {
    final title = event.title?.trim() ?? '';
    if (title.isNotEmpty) return title;

    final raw = event.raw;
    if (raw is Map) {
      for (final key in ['title', 'TITLE']) {
        final value = raw[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return '';
  }

  static String _extractContent(NotificationEvent event) {
    for (final candidate in [
      event.text,
      event.message,
    ]) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final raw = event.raw;
    if (raw is Map) {
      for (final key in [
        'text',
        'TEXT',
        'bigText',
        'BIG_TEXT',
        'summaryText',
        'SUMMARY_TEXT',
        'subText',
        'SUB_TEXT',
        'infoText',
        'INFO_TEXT',
      ]) {
        final value = raw[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }

      final lines = raw['textLines'] ?? raw['TEXT_LINES'];
      if (lines is List && lines.isNotEmpty) {
        return lines.map((e) => e.toString()).join('\n');
      }
    }

    return '';
  }
}

/// Background callback: forward events to the main isolate via SendPort.
@pragma('vm:entry-point')
void _backgroundNotificationCallback(NotificationEvent event) {
  final sendPort = IsolateNameServer.lookupPortByName(_listenerPortName);
  sendPort?.send(event);
}
