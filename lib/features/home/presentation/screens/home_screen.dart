import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mage_chan/features/settings/permission_manager.dart';
import 'package:mage_chan/features/settings/presentation/screens/settings_screen.dart';
import 'package:mage_chan/features/reminder/presentation/screens/reminder_list_screen.dart';
import 'package:mage_chan/features/finance/presentation/screens/finance_form_screen.dart';
import '../widgets/greeting_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/finance_summary_card.dart';
import 'package:mage_chan/services/notification_service.dart';
import 'package:mage_chan/services/social_notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _devMode = false;

  @override
  void initState() {
    super.initState();
    _loadDevMode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      PermissionManager.requestAllPermissions(context);
    });
  }

  Future<void> _loadDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _devMode = prefs.getBool('dev_mode') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Mage-chan Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    _loadDevMode();
                    await SocialNotificationService().startListening();
                  },
                ),
              ],
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 8),
                  const GreetingCard(),
                  const SizedBox(height: 16),
                  const StatsGrid(),
                  const SizedBox(height: 16),
                  const FinanceSummaryCard(),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(context, Icons.add_alarm, "ตั้งเตือน", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen()));
                        }),
                        _buildActionButton(context, Icons.payments, "จดบัญชี", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceFormScreen()));
                        }),
                        // Show Test button only when dev mode is ON
                        if (_devMode)
                          _buildActionButton(context, Icons.warning_amber_rounded, "Test แจ้งเตือน", () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กรุณาล็อกหน้าจอ (ปิดจอ) ภายใน 5 วินาที เพื่อทดสอบ!')),
                            );
                            
                            await Future.delayed(const Duration(seconds: 5));
                            
                            if (!mounted) return;
                            await NotificationService().showFullScreenAlarm(
                              id: 999,
                              title: '📋 ทดสอบแจ้งเตือน',
                              body: '⏰ ${TimeOfDay.now().format(context)} น.\nถึงเวลาแล้วเจ้าคะ',
                              payload: {
                                'title': 'ทดสอบแจ้งเตือน',
                                'time': TimeOfDay.now().format(context),
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          elevation: 2,
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
