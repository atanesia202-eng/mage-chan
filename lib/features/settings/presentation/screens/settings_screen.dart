import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mage_chan/providers/theme_provider.dart';
import 'package:mage_chan/services/social_notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackgroundServiceRunning = false;
  bool _hasNotificationAccess = false;
  
  // Easter egg: Developer Mode
  int _aboutTapCount = 0;
  bool _devMode = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _checkNotificationAccess();
    _loadDevMode();
  }

  Future<void> _loadDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _devMode = prefs.getBool('dev_mode') ?? false;
      });
    }
  }

  Future<void> _setDevMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_mode', value);
    if (mounted) {
      setState(() {
        _devMode = value;
      });
    }
  }

  void _handleAboutTap() {
    _aboutTapCount++;
    final remaining = 7 - _aboutTapCount;
    
    if (_aboutTapCount >= 7) {
      // Toggle dev mode ON
      _aboutTapCount = 0;
      if (!_devMode) {
        _setDevMode(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 เปิดโหมดนักพัฒนาแล้ว!'),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    } else if (_aboutTapCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อีก $remaining ครั้ง จะเปิดโหมดนักพัฒนา...'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  Future<void> _checkNotificationAccess() async {
    try {
      final hasAccess = await NotificationsListener.hasPermission;
      if (mounted) {
        setState(() {
          _hasNotificationAccess = hasAccess ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error checking notification access: $e');
    }
  }

  void _toggleNotificationAccess(bool value) async {
    try {
      if (value) {
        await NotificationsListener.openPermissionSettings();
      }
      await Future.delayed(const Duration(seconds: 2));
      await _checkNotificationAccess();
      if (_hasNotificationAccess) {
        await SocialNotificationService().startListening();
      }
    } catch (e) {
      debugPrint('Error opening settings: $e');
    }
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await FlutterBackgroundService().isRunning();
    if (mounted) {
      setState(() {
        _isBackgroundServiceRunning = isRunning;
      });
    }
  }

  void _toggleBackgroundService(bool value) async {
    final service = FlutterBackgroundService();
    if (value) {
      service.startService();
    } else {
      service.invoke("stopService");
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    _checkServiceStatus();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = currentTheme == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text('การตั้งค่า (Settings)')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('โหมดมืด (Dark Mode)'),
            subtitle: Text(isDark ? 'เปิดอยู่ — ธีมมืด' : 'ปิดอยู่ — ธีมสว่าง'),
            value: isDark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).setTheme(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_sync),
            title: const Text('การทำงานเบื้องหลัง (Background Service)'),
            subtitle: const Text('เปิดเพื่อให้แจ้งเตือนทำงานแม้ออกจากแอป'),
            value: _isBackgroundServiceRunning,
            onChanged: _toggleBackgroundService,
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('ดักจับการแจ้งเตือน (Notification Access)'),
            subtitle: const Text('เปิดเพื่อซิงค์ข้อความ LINE, FB, IG'),
            value: _hasNotificationAccess,
            onChanged: _toggleNotificationAccess,
          ),
          const Divider(),
          
          // Easter egg: tap 7 times to enable dev mode
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('เกี่ยวกับแอป'),
            subtitle: const Text('Mage-chan Assistant v1.0.0\nผู้ช่วยส่วนตัวสุดน่ารัก'),
            onTap: _handleAboutTap,
          ),
          
          // Developer mode toggle (only visible when dev mode is ON)
          if (_devMode) ...[
            const Divider(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.developer_mode, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text('โหมดนักพัฒนา', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade300)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('แสดงปุ่ม Test แจ้งเตือน'),
                    subtitle: const Text('แสดงปุ่มทดสอบบนหน้า Dashboard'),
                    value: _devMode,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      _setDevMode(value);
                      if (!value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔒 ปิดโหมดนักพัฒนาแล้ว'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
