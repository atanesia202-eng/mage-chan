import 'package:isar/isar.dart';

part 'reminder_model.g.dart';

@collection
class ReminderModel {
  Id id = Isar.autoIncrement;

  late String title;

  /// Primary time in format "HH:mm" (kept for backward compatibility)
  late String time;

  /// Additional times in format "HH:mm" (e.g. ["14:00", "17:00"])
  List<String> additionalTimes = [];

  @ignore
  List<String> get allTimes {
    final times = [time, ...additionalTimes];
    // Sort times
    times.sort();
    return times;
  }

  /// Type of repeat: "daily", "custom", "specific_date"
  late String repeatType;

  /// If type is "custom", this contains the days of the week (1=Monday, 7=Sunday)
  List<int>? customDaysList;

  /// If type is "specific_date", this contains the specific date in millisecondsSinceEpoch
  int? specificDate;

  bool isCompleted = false;
}
