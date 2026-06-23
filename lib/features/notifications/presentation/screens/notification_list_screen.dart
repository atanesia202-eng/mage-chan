import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../database/isar_service.dart';
import '../../../../models/social_notification_model.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {

  /// Map package name to a friendly name and icon/color
  static const Map<String, _AppInfo> _appRegistry = {
    'jp.naver.line.android': _AppInfo('LINE', Colors.green, '💬'),
    'com.facebook.orca': _AppInfo('Messenger', Colors.blue, '💬'),
    'com.facebook.katana': _AppInfo('Facebook', Colors.indigo, '📘'),
    'com.instagram.android': _AppInfo('Instagram', Colors.pink, '📷'),
    'com.whatsapp': _AppInfo('WhatsApp', Colors.teal, '💬'),
    'com.twitter.android': _AppInfo('X (Twitter)', Colors.blueGrey, '🐦'),
    'org.telegram.messenger': _AppInfo('Telegram', Colors.lightBlue, '✈️'),
  };

  static _AppInfo _getAppInfo(String packageName) {
    return _appRegistry[packageName] ?? _AppInfo(packageName, Colors.grey, '🔔');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งเตือนโซเชียลวันนี้')),
      body: StreamBuilder<List<SocialNotificationModel>>(
        stream: IsarService.watchSocialNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          // Filter today's notifications only
          final todayNotifs = snapshot.data!.where((n) =>
            n.timestamp.year == now.year &&
            n.timestamp.month == now.month &&
            n.timestamp.day == now.day
          ).toList();

          if (todayNotifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('ไม่มีแจ้งเตือนวันนี้', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('ข้อความจาก LINE, IG, FB จะปรากฏที่นี่', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            );
          }

          // Group by appName
          final Map<String, List<SocialNotificationModel>> grouped = {};
          for (final n in todayNotifs) {
            grouped.putIfAbsent(n.packageName, () => []).add(n);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary chips at the top
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: grouped.entries.map((entry) {
                  final info = _getAppInfo(entry.key);
                  return _buildAppChip(theme, info, entry.value.length, entry.key);
                }).toList(),
              ),
              const SizedBox(height: 24),

              // All notifications list
              Text('รายละเอียดแจ้งเตือน', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ...grouped.entries.expand((entry) {
                final info = _getAppInfo(entry.key);
                return [
                  // App Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(info.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(info.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: info.color)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${entry.value.length} ข้อความ', style: TextStyle(color: info.color, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  // Individual messages
                  ...entry.value.map((notif) {
                    final time = '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')}';
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: info.color.withValues(alpha: 0.15),
                          child: Text(notif.title.isNotEmpty ? notif.title[0].toUpperCase() : '?',
                            style: TextStyle(color: info.color, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(notif.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        trailing: Text(time, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        onTap: () => _openApp(entry.key),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ];
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppChip(ThemeData theme, _AppInfo info, int count, String packageName) {
    return GestureDetector(
      onTap: () => _openApp(packageName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: info.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(info.name, style: TextStyle(fontWeight: FontWeight.bold, color: info.color, fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: info.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openApp(String packageName) {
    // Try to launch the app using Android Intent
    // We'll use platform channel or url_launcher as fallback
    try {
      // Use Android Intent to open the app
      _launchApp(packageName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดแอป $packageName ได้')),
        );
      }
    }
  }

  Future<void> _launchApp(String packageName) async {
    // Use flutter's platform channel to launch app by package name
    // For now, we'll use a simple approach with url_launcher or intent
    try {
      // Android-specific: launch app via Intent
      final intent = AndroidIntent(packageName: packageName);
      await intent.launch();
    } catch (e) {
      debugPrint('Could not launch app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดแอป ${_getAppInfo(packageName).name} ได้')),
        );
      }
    }
  }
}

/// Simple helper to hold app display info
class _AppInfo {
  final String name;
  final Color color;
  final String emoji;

  const _AppInfo(this.name, this.color, this.emoji);
}

/// Minimal AndroidIntent helper using MethodChannel
class AndroidIntent {
  final String packageName;
  const AndroidIntent({required this.packageName});

  Future<void> launch() async {
    try {
      const channel = MethodChannel('mage_chan/intent');
      await channel.invokeMethod('launchApp', {'packageName': packageName});
    } catch (e) {
      debugPrint('AndroidIntent launch failed: $e');
      rethrow;
    }
  }
}
