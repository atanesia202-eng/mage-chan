import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../database/isar_service.dart';

class FinanceSummaryCard extends StatefulWidget {
  const FinanceSummaryCard({super.key});

  @override
  State<FinanceSummaryCard> createState() => _FinanceSummaryCardState();
}

class _FinanceSummaryCardState extends State<FinanceSummaryCard> {
  StreamSubscription? _incomeSub;
  StreamSubscription? _txSub;
  StreamSubscription? _fixedExpenseSub;

  double _budget = 0.0;
  double _expense = 0.0;
  double _fixedExpenseTotal = 0.0; // The total monthly equivalent to save

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    _incomeSub = IsarService.watchFixedIncome().listen((incomes) {
      _calculateBudget(incomes);
    });
    
    _txSub = IsarService.watchTransactions().listen((txs) {
      _calculateExpenses(txs);
    });
    
    _fixedExpenseSub = IsarService.watchFixedExpenses().listen((expenses) {
      _calculateFixedExpenses(expenses);
    });
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  void _calculateBudget(List<dynamic> incomes) {
    final monthYear = _getCurrentMonthYear();
    double budget = 0;
    for (var inc in incomes) {
      if (inc.monthYear == monthYear) {
        budget = inc.amount;
        break;
      }
    }
    if (mounted) setState(() => _budget = budget);
  }

  void _calculateExpenses(List<dynamic> txs) {
    final now = DateTime.now();
    double totalExpense = 0;
    for (var tx in txs) {
      if (tx.date.year == now.year && tx.date.month == now.month && tx.type == 'expense') {
        totalExpense += tx.amount;
      }
    }
    if (mounted) setState(() => _expense = totalExpense);
  }

  void _calculateFixedExpenses(List<dynamic> expenses) {
    double total = 0;
    for (var e in expenses) {
      total += e.monthlyEquivalent;
    }
    if (mounted) setState(() => _fixedExpenseTotal = total);
  }

  Future<void> _loadInitialData() async {
    final monthYear = _getCurrentMonthYear();
    
    final inc = await IsarService.getFixedIncome(monthYear);
    if (inc != null && mounted) setState(() => _budget = inc.amount);

    final txs = await IsarService.getAllTransactions();
    _calculateExpenses(txs);
    
    final fixedExps = await IsarService.getAllFixedExpenses();
    _calculateFixedExpenses(fixedExps);
  }

  @override
  void dispose() {
    _incomeSub?.cancel();
    _txSub?.cancel();
    _fixedExpenseSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // งบคงเหลือที่ใช้ได้ = งบที่ตั้งไว้ - รายจ่ายที่จ่ายไปแล้ว - (รายจ่ายประจำที่ต้องหักเก็บต่อเดือน)
    final balance = _budget - _expense - _fixedExpenseTotal;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "งบประมาณเดือนนี้ (คงเหลือ)",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFinanceItem(context, "งบที่ตั้งไว้", "฿${_budget.toStringAsFixed(0)}", Colors.green),
                _buildFinanceItem(context, "หักเก็บประจำ", "-฿${_fixedExpenseTotal.toStringAsFixed(0)}", theme.colorScheme.secondary),
                _buildFinanceItem(context, "รายจ่ายทั่วไป", "-฿${_expense.toStringAsFixed(0)}", Colors.redAccent),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('เงินที่ใช้ได้จริง:', style: theme.textTheme.titleMedium),
                Text(
                  "฿${balance.toStringAsFixed(0)}", 
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? theme.colorScheme.primary : Colors.redAccent,
                  )
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceItem(BuildContext context, String title, String amount, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
