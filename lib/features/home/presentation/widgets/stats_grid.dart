import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mage_chan/features/reminder/presentation/screens/reminder_list_screen.dart';
import 'package:mage_chan/features/calls/presentation/screens/call_logs_screen.dart';
import 'package:mage_chan/features/notifications/presentation/screens/notification_list_screen.dart';
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
            "Reminders",
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
            "Notifications",
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
            "Calls Today",
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
          _buildBackgroundStatusCard(context),
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

  Widget _buildBackgroundStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    return _BackgroundStatusCard(theme: theme);
  }
}

/// Stateful widget สำหรับ Service card เพื่อ auto-refresh ทุก 30 วินาที
class _BackgroundStatusCard extends StatefulWidget {
  final ThemeData theme;

  const _BackgroundStatusCard({required this.theme});

  @override
  State<_BackgroundStatusCard> createState() => _BackgroundStatusCardState();
}

class _BackgroundStatusCardState extends State<_BackgroundStatusCard> {
  late Timer _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    try {
      final running = await FlutterBackgroundService().isRunning();
      if (mounted) {
        setState(() => _isRunning = running);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The user requested the Active color to be grey for now
    final color = Colors.grey; 
    final title = "Service";
    final value = _isRunning ? "Active" : "Stopped";

    return Card(
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
                Icon(_isRunning ? Icons.cloud_done : Icons.cloud_off, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: widget.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: widget.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
