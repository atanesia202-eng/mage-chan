import 'package:isar/isar.dart';

part 'fixed_expense_model.g.dart';

@collection
class FixedExpenseModel {
  Id id = Isar.autoIncrement;

  /// Name of the expense, e.g., "Student Loan", "Internet"
  late String title;

  /// The amount of the expense
  late double amount;

  /// "monthly" or "yearly"
  late String frequency;

  /// Calculate the monthly equivalent amount
  @ignore
  double get monthlyEquivalent {
    if (frequency == 'yearly') {
      return amount / 12;
    }
    return amount;
  }
}
