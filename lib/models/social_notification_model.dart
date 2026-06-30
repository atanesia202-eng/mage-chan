import 'package:isar/isar.dart';

part 'social_notification_model.g.dart';

@collection
class SocialNotificationModel {
  Id id = Isar.autoIncrement;

  /// 'line', 'facebook', 'instagram'
  late String appName; 

  /// Package name, e.g., 'jp.naver.line.android'
  late String packageName; 

  /// Sender name or notification title
  late String title; 

  /// Message content
  late String content; 

  /// 'message' = chat message, 'notification' = social alert (likes, comments, etc.)
  /// Empty string for legacy data (treated as 'message')
  String type = '';

  /// Time when the notification was received
  late DateTime timestamp;
}
