import 'package:isar/isar.dart';

part 'finance_model.g.dart';

@collection
class FixedIncomeModel {
  Id id = Isar.autoIncrement;

  /// Base salary or income
  late double amount;

  /// Month and year indicator, e.g., "2026-06"
  late String monthYear;
}

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  late String title;
  
  late double amount;

  /// "income" or "expense"
  late String type;

  late DateTime date;

  /// true if this is a recurring daily/monthly expense
  bool isRecurring = false;
}
