import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../database/isar_service.dart';
import '../../../../models/reminder_model.dart';
import 'reminder_form_screen.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _calculateTargetDate(ReminderModel r, String timeString, DateTime now) {
    final timeParts = timeString.split(':');
    if (timeParts.length != 2) return null;
    final targetHour = int.tryParse(timeParts[0]) ?? 0;
    final targetMinute = int.tryParse(timeParts[1]) ?? 0;

    DateTime targetDate = DateTime(now.year, now.month, now.day, targetHour, targetMinute);

    if (r.repeatType == 'daily') {
      if (targetDate.isBefore(now)) {
        targetDate = targetDate.add(const Duration(days: 1));
      }
    } else if (r.repeatType == 'custom' && r.customDaysList != null && r.customDaysList!.isNotEmpty) {
      while (!r.customDaysList!.contains(targetDate.weekday) || targetDate.isBefore(now)) {
        targetDate = targetDate.add(const Duration(days: 1));
      }
    } else if (r.repeatType == 'specific_date' && r.specificDate != null) {
      final sDate = DateTime.fromMillisecondsSinceEpoch(r.specificDate!);
      targetDate = DateTime(sDate.year, sDate.month, sDate.day, targetHour, targetMinute);
      if (targetDate.isBefore(now)) {
        return null; // Passed
      }
    } else {
      return null;
    }
    return targetDate;
  }

  String _formatCountdown(DateTime targetDate, DateTime now) {
    final diff = targetDate.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    
    if (days > 0) return 'อีก $days วัน $hours ชม. $minutes นาที';
    if (hours > 0) return 'อีก $hours ชม. $minutes นาที';
    return 'อีก $minutes นาที';
  }

  Widget _buildTimeChips(BuildContext context, ReminderModel r, ThemeData theme) {
    final now = DateTime.now();
    final times = r.allTimes;
    
    // Find the closest upcoming time
    DateTime? closestDate;
    String? closestTimeString;
    
    for (final t in times) {
      final targetDate = _calculateTargetDate(r, t, now);
      if (targetDate != null) {
        if (closestDate == null || targetDate.isBefore(closestDate)) {
          closestDate = targetDate;
          closestTimeString = t;
        }
      }
    }

    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: times.map((t) {
        final targetDate = _calculateTargetDate(r, t, now);
        final isPassed = targetDate == null;
        final isClosest = t == closestTimeString;
        
        Color bgColor;
        Color textColor;
        String text;
        
        if (isPassed) {
          bgColor = theme.colorScheme.surfaceContainerHigh;
          textColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
          text = '✅ $t - ผ่านแล้ว';
        } else {
          final countdown = _formatCountdown(targetDate, now);
          text = '⏰ $t - $countdown';
          if (isClosest) {
            bgColor = theme.colorScheme.primaryContainer;
            textColor = theme.colorScheme.onPrimaryContainer;
          } else {
            bgColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.5);
            textColor = theme.colorScheme.onSecondaryContainer;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isClosest ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)) : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: isClosest ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('รายการแจ้งเตือนทั้งหมด')),
      body: StreamBuilder<List<ReminderModel>>(
        stream: IsarService.watchReminders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final reminders = snapshot.data!;
          if (reminders.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการแจ้งเตือน', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final r = reminders[index];
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReminderFormScreen(existingReminder: r)));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_note, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                r.repeatType == 'daily' ? 'ทุกวัน' : 
                                r.repeatType == 'custom' ? 'รายสัปดาห์' : 'เฉพาะวัน',
                                style: TextStyle(fontSize: 10, color: theme.colorScheme.onTertiaryContainer),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTimeChips(context, r, theme),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
