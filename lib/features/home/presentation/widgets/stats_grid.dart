import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mage_chan/features/reminder/presentation/screens/reminder_list_screen.dart';
import 'package:mage_chan/features/calls/presentation/screens/call_logs_screen.dart';
import 'package:mage_chan/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:mage_chan/features/quickbox/presentation/screens/quickbox_list_screen.dart';
import '../../providers/stats_providers.dart';

class StatsGrid extends ConsumerWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(activeRemindersCountProvider);
    final notificationsAsync = ref.watch(todayNotificationsCountProvider);
    final callsAsync = ref.watch(todayCallsCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            context,
            "สิ่งที่ต้องทำ",
            remindersAsync.when(
              data: (count) => count.toString(),
              loading: () => "...",
              error: (_, __) => "0",
            ),
            Icons.alarm,
            Colors.orange,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen()));
            },
          ),
          _buildStatCard(
            context,
            "ข้อความ (14 วัน)",
            notificationsAsync.when(
              data: (count) => count.toString(),
              loading: () => "...",
              error: (_, __) => "0",
            ),
            Icons.notifications_active,
            Colors.blue,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListScreen()));
            },
          ),
          _buildStatCard(
            context,
            "สายโทรเข้าวันนี้",
            callsAsync.when(
              data: (count) => count.toString(),
              loading: () => "...",
              error: (_, __) => "0",
            ),
            Icons.phone_callback,
            Colors.green,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CallLogsScreen()));
            },
          ),
          _buildStatCard(
            context,
            "กล่องเก็บของ",
            "เปิด",
            Icons.inbox,
            Colors.purple,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickBoxListScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
