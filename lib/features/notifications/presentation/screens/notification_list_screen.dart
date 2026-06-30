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

class _NotificationListScreenState extends State<NotificationListScreen>
    with TickerProviderStateMixin {
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
    return _appRegistry[packageName] ??
        _AppInfo(packageName, Colors.grey, '🔔');
  }

  /// Helper: treat empty or missing type as 'message' for backward compat
  static String _effectiveType(SocialNotificationModel n) {
    return (n.type.isEmpty) ? 'message' : n.type;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<SocialNotificationModel>>(
      stream: IsarService.watchSocialNotifications(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('ประวัติข้อความ (14 วัน)')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final now = DateTime.now();
        final cutoffDate = now.subtract(const Duration(days: 14));

        // Filter last 14 days, remove old Facebook App notifications
        var allNotifs = snapshot.data!
            .where((n) =>
                n.timestamp.isAfter(cutoffDate) &&
                n.packageName != 'com.facebook.katana')
            .toList();
        allNotifs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Split into messages and notifications
        final messages =
            allNotifs.where((n) => _effectiveType(n) == 'message').toList();
        final notifications =
            allNotifs.where((n) => _effectiveType(n) == 'notification').toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('ประวัติข้อความ (14 วัน)'),
              bottom: TabBar(
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💬'),
                        const SizedBox(width: 6),
                        const Text('ข้อความ'),
                        const SizedBox(width: 8),
                        _buildBadge(messages.length, Colors.blue),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔔'),
                        const SizedBox(width: 6),
                        const Text('แจ้งเตือน'),
                        const SizedBox(width: 8),
                        _buildBadge(notifications.length, Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _MessagesTab(messages: messages, theme: theme),
                _NotificationsTab(
                    notifications: notifications, theme: theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Tab 1: ข้อความ — with sub-tabs per app (IG, LINE, Messenger, etc.)
// ──────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  final List<SocialNotificationModel> messages;
  final ThemeData theme;

  const _MessagesTab({required this.messages, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'ไม่มีข้อความใน 14 วันที่ผ่านมา',
        subtitle: 'ข้อความจาก LINE, Instagram, Messenger จะแสดงที่นี่',
      );
    }

    // Group by app
    final Map<String, List<SocialNotificationModel>> groupedByApp = {};
    for (final n in messages) {
      groupedByApp.putIfAbsent(n.packageName, () => []).add(n);
    }

    final appKeys = groupedByApp.keys.toList();

    return DefaultTabController(
      length: appKeys.length,
      child: Column(
        children: [
          // Sub-tab bar for apps
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            child: TabBar(
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: appKeys.map((key) {
                final info = _NotificationListScreenState._getAppInfo(key);
                final count = groupedByApp[key]!.length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(info.emoji),
                      const SizedBox(width: 4),
                      Text(info.name),
                      const SizedBox(width: 6),
                      _buildSmallBadge(count, info.color),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Message list for selected app
          Expanded(
            child: TabBarView(
              children: appKeys.map((key) {
                final appNotifs = groupedByApp[key]!;
                return _MessageListView(
                  theme: theme,
                  packageName: key,
                  notifs: appNotifs,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Tab 2: แจ้งเตือน — all social alerts grouped by date
// ──────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  final List<SocialNotificationModel> notifications;
  final ThemeData theme;

  const _NotificationsTab(
      {required this.notifications, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 64, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('ไม่มีแจ้งเตือนใน 14 วันที่ผ่านมา',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Likes, Comments, Mentions จะแสดงที่นี่',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<SocialNotificationModel>> groupedByDate = {};
    for (final n in notifications) {
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
            _buildDateHeader(dateKey),
            ...dayNotifs.map((notif) {
              final info = _NotificationListScreenState._getAppInfo(
                  notif.packageName);
              final time =
                  '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')}';
              return _buildNotificationCard(notif, info, time);
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String dateKey) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildNotificationCard(
      SocialNotificationModel notif, _AppInfo info, String time) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: info.color.withValues(alpha: 0.15),
              child: Text(
                info.emoji,
                style: const TextStyle(fontSize: 18),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: info.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                info.name,
                                style: TextStyle(
                                  color: info.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notif.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(time,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.content,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}

// ──────────────────────────────────────────────────────────
// Shared: Message list view (used in Messages tab per app)
// ──────────────────────────────────────────────────────────

class _MessageListView extends StatelessWidget {
  final ThemeData theme;
  final String packageName;
  final List<SocialNotificationModel> notifs;

  const _MessageListView({
    required this.theme,
    required this.packageName,
    required this.notifs,
  });

  @override
  Widget build(BuildContext context) {
    final info = _NotificationListScreenState._getAppInfo(packageName);

    // Group by date
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
            _buildDateHeader(dateKey),
            ...dayNotifs.map((notif) {
              final time =
                  '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')}';
              return _buildMessageCard(notif, info, time);
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String dateKey) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildMessageCard(
      SocialNotificationModel notif, _AppInfo info, String time) {
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
                  notif.title.isNotEmpty
                      ? notif.title[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: info.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(time,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
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
      debugPrint('Could not open app: $e');
    }
  }

  Future<void> _launchApp(String packageName) async {
    try {
      final intent = AndroidIntent(packageName: packageName);
      await intent.launch();
    } catch (e) {
      debugPrint('Could not launch app: $e');
    }
  }
}

// ──────────────────────────────────────────────────────────
// Shared helpers
// ──────────────────────────────────────────────────────────

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
