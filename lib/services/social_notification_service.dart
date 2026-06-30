import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:path_provider/path_provider.dart';
import '../database/isar_service.dart';
import '../models/social_notification_model.dart';

const _listenerPortName = 'mage_chan_social_listener';
const _pendingFileName = 'pending_social_notifications.jsonl';

/// Service that listens for incoming notifications from social media apps
/// and saves them to the local Isar database.
class SocialNotificationService {
  static final SocialNotificationService _instance =
      SocialNotificationService._internal();
  factory SocialNotificationService() => _instance;
  SocialNotificationService._internal();

  ReceivePort? _receivePort;

  /// Package names of social media apps we want to track
  static const Set<String> trackedPackages = {
    'jp.naver.line.android',
    'com.facebook.orca', // Messenger (Chats only)
    // 'com.facebook.katana', // Removed Facebook App to avoid non-chat notifications
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
      debugPrint('[SocialNotif] ▶ Initializing...');
      _setupMainIsolateReceiver();

      // NOTE: do NOT register a handler on
      // MethodChannel('flutter_notification_listener/bg_method') here.
      // The plugin itself owns that channel internally (method 'sink_event')
      // to deliver events into its background isolate and invoke
      // `callbackHandle` for us. setMethodCallHandler only allows ONE
      // handler per channel per isolate — registering our own overwrites
      // the plugin's handler and silently breaks the entire pipeline
      // (this was the actual root cause of notifications never being saved).

      await NotificationsListener.initialize(
        callbackHandle: _backgroundNotificationCallback,
      );
      // Import any pending notifications saved by background callback when app was closed
      await importPendingNotifications();
      debugPrint('[SocialNotif] ✅ Initialized successfully');
    } catch (e, stack) {
      debugPrint('[SocialNotif] ❌ Init error: $e\n$stack');
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
      debugPrint(
        '[SocialNotif] 📨 Received event in main isolate: ${message.runtimeType}',
      );
      // FIX: Accept Map<String, String> instead of NotificationEvent.
      // SendPort can only transmit primitive types, Lists, and Maps — not custom objects.
      if (message is Map) {
        _handleParsedNotification(Map<String, String>.from(message));
      }
    });
    debugPrint('[SocialNotif] 📡 Main isolate receiver registered');
  }

  /// Re-register the IsolateNameServer port (call on app resume).
  void reRegisterPort() {
    debugPrint('[SocialNotif] 🔄 Re-registering main isolate port...');
    _setupMainIsolateReceiver();
  }

  /// Start or restart the Android notification listener service.
  Future<bool> startListening() async {
    try {
      final perm = await NotificationsListener.hasPermission ?? false;
      debugPrint('[SocialNotif] 🔑 Permission: $perm');
      if (!perm) {
        debugPrint('[SocialNotif] ⚠️ No notification listener permission!');
        return false;
      }

      final running = await NotificationsListener.isRunning ?? false;
      debugPrint('[SocialNotif] 🏃 Service running: $running');
      if (!running) {
        await NotificationsListener.startService(
          foreground: true,
          title: 'Mage-chan Notification Listener',
          description: 'กำลังดักจับแจ้งเตือนเพื่อนายท่าน...',
        );
        debugPrint('[SocialNotif] ✅ Listener service started');
      }

      // Import pending notifications from background saves
      await importPendingNotifications();

      debugPrint('[SocialNotif] ✅ Listening active');
      return true;
    } catch (e, stack) {
      debugPrint('[SocialNotif] ❌ Start error: $e\n$stack');
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

  Future<bool> isListenerRunning() async {
    return await NotificationsListener.isRunning ?? false;
  }

  /// Process a parsed notification Map in the main isolate and persist it to Isar.
  static Future<void> _handleParsedNotification(
    Map<String, String> data,
  ) async {
    try {
      final appName = data['appName'] ?? '';
      final packageName = data['packageName'] ?? '';
      final title = data['title'] ?? '';
      final content = data['content'] ?? '';

      debugPrint(
        '[SocialNotif] 📝 Handling parsed: $appName | "$title" | "$content"',
      );

      if (title.isEmpty && content.isEmpty) {
        debugPrint('[SocialNotif] ⏭️ Empty title and content, skipping');
        return;
      }

      final notif = SocialNotificationModel()
        ..appName = appName
        ..packageName = packageName
        ..title = title
        ..content = content.isNotEmpty ? content : title
        ..timestamp = DateTime.now();

      await IsarService.saveSocialNotification(notif);
      debugPrint('[SocialNotif] ✅ Saved: $appName | $title | $content');
    } catch (e, stack) {
      debugPrint(
        '[SocialNotif] ❌ Error handling parsed notification: $e\n$stack',
      );
    }
  }

  /// Process a notification in the main isolate and persist it.
  /// Kept for backward compatibility.
  static Future<void> handleNotificationEvent(NotificationEvent event) async {
    try {
      final data = extractDataFromEvent(event);
      if (data == null) return;
      await _handleParsedNotification(data);
    } catch (e, stack) {
      debugPrint('[SocialNotif] ❌ Error handling notification: $e\n$stack');
    }
  }

  /// Extract title, content, appName, packageName from a NotificationEvent
  /// into a simple Map<String, String> that can be sent through SendPort
  /// or saved to a pending file.
  ///
  /// Returns null if the event should be skipped (not tracked, empty, etc.)
  static Map<String, String>? extractDataFromEvent(NotificationEvent event) {
    final packageName = event.packageName ?? '';

    if (!trackedPackages.contains(packageName)) {
      return null;
    }

    var title = _extractTitle(event);
    var content = _extractContent(event);

    // Filter out non-message notifications (Likes, Comments, Mentions, Adds)
    if (!_isLikelyChatMessage(packageName, title, content)) {
      debugPrint('[SocialNotif] ⏭️ Filtered out non-message notification: "$title" | "$content"');
      return null;
    }

    // DEBUG: Force save even if empty
    if (title.isEmpty) title = '(No Title)';
    if (content.isEmpty) content = '(No Content)';
    if (event.isGroup == true) content = '[Group] $content';

    final appName = appNames[packageName] ?? packageName;

    return {
      'appName': appName,
      'packageName': packageName,
      'title': title,
      'content': content,
    };
  }

  /// Heuristic to detect if a notification is a chat message rather than a social alert
  static bool _isLikelyChatMessage(String packageName, String title, String content) {
    // Dedicated messaging apps are almost always messages
    if (packageName == 'com.facebook.orca' || packageName == 'com.whatsapp' || packageName == 'org.telegram.messenger') {
      return true;
    }

    // LINE: also a dedicated messaging app
    if (packageName == 'jp.naver.line.android') {
      return true;
    }

    final lowerContent = content.toLowerCase();
    final lowerTitle = title.toLowerCase();

    // --- Instagram-specific filtering ---
    if (packageName == 'com.instagram.android') {
      // Instagram DM notifications typically say "sent you a message" or just show
      // the message content directly with the sender's name as title.
      // Non-DM notifications say things like "liked your photo", "started following you", etc.

      // Whitelist: keywords that indicate a DM
      final igDmKeywords = [
        'sent you a message', 'ส่งข้อความ', 'sent a photo', 'sent a video',
        'sent an audio', 'sent a reel', 'sent a post', 'sent a story',
        'ส่งรูปภาพ', 'ส่งวิดีโอ', 'ส่งโพสต์', 'ส่งสตอรี่',
      ];

      for (final kw in igDmKeywords) {
        if (lowerContent.contains(kw) || lowerTitle.contains(kw)) {
          return true; // This IS a DM
        }
      }

      // Blacklist: keywords that indicate a social notification (NOT a DM)
      final igSocialKeywords = [
        'liked', 'ถูกใจ', 'commented', 'แสดงความคิดเห็น',
        'mentioned', 'กล่าวถึง', 'started following', 'เริ่มติดตาม',
        'tagged', 'แท็ก', 'is live', 'ถ่ายทอดสด', 'going live',
        'added to their story', 'เพิ่มลงในสตอรี่',
        'shared a post', 'shared a reel',
        'recently posted', 'โพสต์ใหม่',
        'reacted', 'replied to your story', 'ตอบกลับสตอรี่',
        'new follower', 'follow request', 'คำขอติดตาม',
        'suggested for you', 'แนะนำสำหรับคุณ',
        'your post', 'your photo', 'your reel', 'your story',
        'โพสต์ของคุณ', 'รูปของคุณ',
      ];

      for (final kw in igSocialKeywords) {
        if (lowerContent.contains(kw) || lowerTitle.contains(kw)) {
          return false; // NOT a DM, filter it out
        }
      }

      // If we can't determine, default to filtering OUT for IG
      // (better to miss a DM than to flood with social noise)
      debugPrint('[SocialNotif] ⚠️ IG notification unclassified, filtering out: "$title" | "$content"');
      return false;
    }

    // --- General filtering for other apps (Twitter, etc.) ---
    final nonMessageKeywords = [
      'ถูกใจ', 'แสดงความคิดเห็น', 'กล่าวถึง', 'เพิ่มคุณเป็นเพื่อน', 'กำลังถ่ายทอดสด',
      'liked', 'commented', 'mentioned', 'added you', 'is live', 'followed you',
      'เริ่มติดตามคุณ', 'reacted', 'replied to your',
    ];

    for (final kw in nonMessageKeywords) {
      if (lowerContent.contains(kw) || lowerTitle.contains(kw)) {
        return false;
      }
    }

    return true;
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
    for (final candidate in [event.text, event.message]) {
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

  /// Import pending notifications saved by the background callback to Isar.
  static Future<int> importPendingNotifications() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_pendingFileName');
      if (!await file.exists()) {
        debugPrint('[SocialNotif] 📂 No pending file found');
        return 0;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        debugPrint('[SocialNotif] 📂 Pending file is empty');
        return 0;
      }

      final lines = content.trim().split('\n');
      int imported = 0;

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          final notif = SocialNotificationModel()
            ..appName = map['appName'] as String
            ..packageName = map['packageName'] as String
            ..title = map['title'] as String
            ..content = map['content'] as String
            ..timestamp = DateTime.fromMillisecondsSinceEpoch(
              map['timestamp'] as int,
            );

          await IsarService.saveSocialNotification(notif);
          imported++;
        } catch (e) {
          debugPrint('[SocialNotif] ⚠️ Error importing line: $e');
        }
      }

      // Clear the file after successful import
      await file.writeAsString('');
      debugPrint('[SocialNotif] 📥 Imported $imported pending notifications');
      return imported;
    } catch (e) {
      debugPrint('[SocialNotif] ❌ Error importing pending: $e');
      return 0;
    }
  }

  /// Get count of pending notifications in the backup file
  static Future<int> getPendingCount() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_pendingFileName');
      if (!await file.exists()) return 0;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return 0;
      return content
          .trim()
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .length;
    } catch (e) {
      return 0;
    }
  }
}

/// Background callback: extract data from the notification event, then
/// forward as a simple Map to the main isolate via SendPort,
/// or save to a pending file if the main isolate is not available.
///
/// IMPORTANT: SendPort.send() can only transmit primitive types (null, num,
/// bool, String), Lists, Maps, SendPorts, and typed data lists.
/// Custom objects like NotificationEvent CANNOT be sent — they will throw
/// an ArgumentError. That's why we extract data into a Map<String, String> first.
@pragma('vm:entry-point')
void _backgroundNotificationCallback(NotificationEvent event) {
  try {
    final packageName = event.packageName ?? 'unknown';
    print('[SocialNotif:BG] 🔔 Callback fired: $packageName');

    // DEBUG: Dump raw event to file
    _debugDumpRawEvent(event);

    // Extract data into a simple Map (serializable via SendPort)
    final data = SocialNotificationService.extractDataFromEvent(event);
    if (data == null) {
      print('[SocialNotif:BG] ⏭️ Event filtered out (not tracked / empty)');
      return;
    }

    print(
      '[SocialNotif:BG] 📝 Extracted: ${data['appName']} | "${data['title']}" | "${data['content']}"',
    );

    // Try forwarding to main isolate for immediate processing
    final sendPort = IsolateNameServer.lookupPortByName(_listenerPortName);
    if (sendPort != null) {
      // FIX: Send Map<String, String> instead of NotificationEvent object.
      // SendPort cannot serialize custom Dart objects.
      sendPort.send(data);
      print('[SocialNotif:BG] ✅ Forwarded Map to main isolate');
    } else {
      // Main isolate is dead — save to pending file for later import
      print('[SocialNotif:BG] ⚠️ Main isolate not available, saving to file');
      _saveToPendingFile(data);
    }
  } catch (e) {
    print('[SocialNotif:BG] ❌ Callback error: $e');
  }
}

/// Save parsed notification data to a JSONL file for later import into Isar.
Future<void> _saveToPendingFile(Map<String, String> data) async {
  try {
    final jsonData = jsonEncode({
      ...data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_pendingFileName');
    await file.writeAsString('$jsonData\n', mode: FileMode.append);
    print('[SocialNotif:BG] ✅ Saved to pending file');
  } catch (e) {
    print('[SocialNotif:BG] ❌ Error saving to file: $e');
  }
}

Future<void> _debugDumpRawEvent(NotificationEvent event) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/debug_notifications.jsonl');
    final Map<String, dynamic> debugData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'packageName': event.packageName,
      'title': event.title,
      'text': event.text,
      'isGroup': event.isGroup,
      'raw': event.raw,
    };
    await file.writeAsString(
      '${jsonEncode(debugData)}\n',
      mode: FileMode.append,
    );
  } catch (e) {
    print('[SocialNotif:BG] ❌ Debug dump error: $e');
  }
}
