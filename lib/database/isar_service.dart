import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reminder_model.dart';
import '../models/finance_model.dart';
import '../models/social_notification_model.dart';
import '../models/fixed_expense_model.dart';

class IsarService {
  static late Isar db;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [
        ReminderModelSchema,
        FixedIncomeModelSchema,
        TransactionModelSchema,
        SocialNotificationModelSchema,
        FixedExpenseModelSchema,
      ],
      directory: dir.path,
    );
  }

  // --- Fixed Expense CRUD ---
  static Future<void> saveFixedExpense(FixedExpenseModel expense) async {
    await db.writeTxn(() async {
      await db.fixedExpenseModels.put(expense);
    });
  }

  static Future<void> deleteFixedExpense(int id) async {
    await db.writeTxn(() async {
      await db.fixedExpenseModels.delete(id);
    });
  }

  static Stream<List<FixedExpenseModel>> watchFixedExpenses() {
    return db.fixedExpenseModels.where().watch(fireImmediately: true);
  }
  
  static Future<List<FixedExpenseModel>> getAllFixedExpenses() async {
    return await db.fixedExpenseModels.where().findAll();
  }

  // --- Reminder CRUD ---
  static Future<void> saveReminder(ReminderModel reminder) async {
    await db.writeTxn(() async {
      await db.reminderModels.put(reminder);
    });
  }

  static Future<void> deleteReminder(int id) async {
    await db.writeTxn(() async {
      await db.reminderModels.delete(id);
    });
  }

  static Stream<List<ReminderModel>> watchReminders() {
    return db.reminderModels.where().watch(fireImmediately: true);
  }

  static Future<List<ReminderModel>> getAllReminders() async {
    return await db.reminderModels.where().findAll();
  }

  // --- Finance CRUD ---
  static Future<void> saveFixedIncome(FixedIncomeModel income) async {
    await db.writeTxn(() async {
      await db.fixedIncomeModels.put(income);
    });
  }

  static Future<FixedIncomeModel?> getFixedIncome(String monthYear) async {
    return await db.fixedIncomeModels.filter().monthYearEqualTo(monthYear).findFirst();
  }

  static Future<void> saveTransaction(TransactionModel transaction) async {
    await db.writeTxn(() async {
      await db.transactionModels.put(transaction);
    });
  }

  static Future<List<TransactionModel>> getAllTransactions() async {
    return await db.transactionModels.where().findAll();
  }

  static Stream<List<FixedIncomeModel>> watchFixedIncome() {
    return db.fixedIncomeModels.where().watch(fireImmediately: true);
  }

  static Stream<List<TransactionModel>> watchTransactions() {
    return db.transactionModels.where().watch(fireImmediately: true);
  }

  // --- Social Notification CRUD ---
  static Future<void> saveSocialNotification(SocialNotificationModel notif) async {
    await db.writeTxn(() async {
      await db.socialNotificationModels.put(notif);
    });
  }

  static Stream<List<SocialNotificationModel>> watchSocialNotifications() {
    return db.socialNotificationModels.where().sortByTimestampDesc().watch(fireImmediately: true);
  }

  static Future<List<SocialNotificationModel>> getSocialNotificationsByApp(String appName) async {
    return await db.socialNotificationModels.filter().appNameEqualTo(appName).sortByTimestampDesc().findAll();
  }
}
