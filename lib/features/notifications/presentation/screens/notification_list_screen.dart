import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../database/isar_service.dart';
import '../../../../models/social_notification_model.dart';
import 'package:intl/intl.dart';

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

    return StreamBuilder<List<SocialNotificationModel>>(
      stream: IsarService.watchSocialNotifications(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('ประวัติการแจ้งเตือน')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final now = DateTime.now();
        final cutoffDate = now.subtract(const Duration(days: 14));

        // Filter last 14 days, remove old Facebook App notifications, and sort by newest first
        var notifs = snapshot.data!
            .where((n) => n.timestamp.isAfter(cutoffDate) && n.packageName != 'com.facebook.katana')
            .toList();
        notifs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (notifs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('ประวัติการแจ้งเตือน')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('ไม่มีแจ้งเตือนใน 14 วันที่ผ่านมา', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('ข้อความจากแชทต่างๆ จะปรากฏที่นี่', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        // Group by appName
        final Map<String, List<SocialNotificationModel>> groupedByApp = {};
        for (final n in notifs) {
          groupedByApp.putIfAbsent(n.packageName, () => []).add(n);
        }

        final appKeys = groupedByApp.keys.toList();

        return DefaultTabController(
          length: appKeys.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('ประวัติข้อความ (14 วัน)'),
              bottom: TabBar(
                isScrollable: true,
                tabs: appKeys.map((key) {
                  final info = _getAppInfo(key);
                  final count = groupedByApp[key]!.length;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(info.emoji),
                        const SizedBox(width: 4),
                        Text(info.name),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count', style: TextStyle(color: info.color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            body: TabBarView(
              children: appKeys.map((key) {
                final appNotifs = groupedByApp[key]!;
                return _buildAppMessageList(theme, key, appNotifs);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppMessageList(ThemeData theme, String packageName, List<SocialNotificationModel> notifs) {
    final info = _getAppInfo(packageName);

    // Group by Date String
    final Map<String, List<SocialNotificationModel>> groupedByDate = {};
    for (final n in notifs) {
      final dateStr = _formatDateGroup(n.timestamp);
      groupedByDate.putIfAbsent(dateStr, () => []).add(n);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedByDate.length,
      itemBuilder: (context, index) {
        final dateKey = groupedByDate.keys.elementAt(index);
        final dayNotifs = groupedByDate[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      dateKey,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(indent: 16)),
                ],
              ),
            ),
            ...dayNotifs.map((notif) {
              final time = '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')}';
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: info.color.withValues(alpha: 0.3)),
                ),
                child: InkWell(
                  onTap: () => _openApp(packageName),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: info.color.withValues(alpha: 0.15),
                          child: Text(
                            notif.title.isNotEmpty ? notif.title[0].toUpperCase() : '?',
                            style: TextStyle(color: info.color, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(time, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.content,
                                style: const TextStyle(fontSize: 14, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'วันนี้';
    } else if (targetDate == yesterday) {
      return 'เมื่อวาน';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  void _openApp(String packageName) {
    try {
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
    try {
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

class _AppInfo {
  final String name;
  final Color color;
  final String emoji;

  const _AppInfo(this.name, this.color, this.emoji);
}

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
