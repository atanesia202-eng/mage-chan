import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'core/theme/app_theme.dart';
import 'core/plugins/mage_plugin.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/social_notification_service.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'database/isar_service.dart';
import 'providers/theme_provider.dart';
import 'features/reminder/presentation/screens/reminder_alert_screen.dart' as mage_chan_overlay;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Plugin Manager
  final pluginManager = PluginManager();
  await pluginManager.initializeAll();

  // Initialize Database
  await IsarService.initialize();

  try {
    // Initialize Notification Service
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  try {
    // Initialize Background Service
    await BackgroundServiceManager().initialize();
  } catch (e) {
    debugPrint('Background Service init error: $e');
  }

  try {
    // Initialize Social Notification Listener (LINE, FB, IG, etc.)
    await SocialNotificationService().initialize();
    await SocialNotificationService().startListening();
  } catch (e) {
    debugPrint('Social Notification Service init error: $e');
  }

  // Check if app was launched from a notification
  final initialAction = await AwesomeNotifications().getInitialNotificationAction(removeFromActionEvents: true);
  Widget? initialScreen;
  if (initialAction?.payload?['type'] == 'boss_alert') {
    final title = initialAction?.payload?['title'] ?? 'แจ้งเตือน';
    final time = initialAction?.payload?['time'] ?? '';
    initialScreen = mage_chan_overlay.ReminderAlertScreen(
      title: title,
      time: time,
      message: 'ถึงเวลาแล้วเจ้าคะ',
    );
  }

  runApp(
    ProviderScope(
      child: MageChanApp(initialScreen: initialScreen),
    ),
  );
}



class MageChanApp extends ConsumerWidget {
  final Widget? initialScreen;

  const MageChanApp({super.key, this.initialScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mage-chan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: initialScreen ?? const HomeScreen(),
    );
  }
}
