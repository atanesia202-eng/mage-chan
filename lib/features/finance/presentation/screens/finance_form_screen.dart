import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../database/isar_service.dart';
import '../../../../models/finance_model.dart';
import '../../../../models/fixed_expense_model.dart';

/// Custom TextInputFormatter that adds commas to numbers (e.g., 1,000 / 100,000)
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Format with commas
    final formatted = _addCommas(digitsOnly);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
  String _addCommas(String digits) {
    final result = StringBuffer();
    int count = 0;
    
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(digits[i]);
      count++;
    }
    
    return result.toString().split('').reversed.join();
  }
}

/// Helper to parse comma-formatted string to double
double? parseFormattedNumber(String text) {
  final cleaned = text.replaceAll(',', '');
  return double.tryParse(cleaned);
}

/// Helper to format a double with commas for display
String formatNumberWithCommas(double value) {
  final intVal = value.toStringAsFixed(0);
  final result = StringBuffer();
  int count = 0;
  
  for (int i = intVal.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) {
      result.write(',');
    }
    result.write(intVal[i]);
    count++;
  }
  
  return result.toString().split('').reversed.join();
}

class FinanceFormScreen extends StatefulWidget {
  const FinanceFormScreen({super.key});

  @override
  State<FinanceFormScreen> createState() => _FinanceFormScreenState();
}

class _FinanceFormScreenState extends State<FinanceFormScreen> {
  final _budgetController = TextEditingController();
  final _amountController = TextEditingController();
  final _customTitleController = TextEditingController();
  
  // Fixed Expense Controllers
  final _fixedExpenseTitleController = TextEditingController();
  final _fixedExpenseAmountController = TextEditingController();
  String _fixedExpenseFrequency = 'monthly';
  
  String _selectedCategory = 'ค่าอาหาร';
  final List<String> _categories = ['ค่าอาหาร', 'ค่าเดินทาง', 'ค่าบ้าน', 'ค่าน้ำค่าไฟ', 'อื่นๆ'];
  
  double _currentBudget = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }
  
  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }
  
  Future<void> _loadCurrentBudget() async {
    final monthYear = _getCurrentMonthYear();
    final income = await IsarService.getFixedIncome(monthYear);
    if (income != null && mounted) {
      setState(() {
        _currentBudget = income.amount;
        _budgetController.text = formatNumberWithCommas(income.amount);
      });
    }
  }

  void _saveBudget() async {
    final amount = parseFormattedNumber(_budgetController.text);
    if (amount == null) return;
    
    final monthYear = _getCurrentMonthYear();
    var income = await IsarService.getFixedIncome(monthYear);
    if (income == null) {
      income = FixedIncomeModel()
        ..amount = amount
        ..monthYear = monthYear;
    } else {
      income.amount = amount;
    }
    await IsarService.saveFixedIncome(income);
    setState(() {
      _currentBudget = amount;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ตั้งงบประมาณสำเร็จ')));
    }
  }

  void _saveTransaction() async {
    final amount = parseFormattedNumber(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง')));
      return;
    }
    
    String title = _selectedCategory;
    if (_selectedCategory == 'อื่นๆ') {
      if (_customTitleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อรายการ')));
        return;
      }
      title = _customTitleController.text;
    }

    final tx = TransactionModel()
      ..title = title
      ..amount = amount
      ..type = 'expense'
      ..date = DateTime.now();

    await IsarService.saveTransaction(tx);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกรายจ่ายสำเร็จ')));
      Navigator.pop(context);
    }
  }

  void _saveFixedExpense() async {
    final title = _fixedExpenseTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อรายจ่ายประจำ')));
      return;
    }
    
    final amount = parseFormattedNumber(_fixedExpenseAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง')));
      return;
    }

    final expense = FixedExpenseModel()
      ..title = title
      ..amount = amount
      ..frequency = _fixedExpenseFrequency;

    await IsarService.saveFixedExpense(expense);
    
    _fixedExpenseTitleController.clear();
    _fixedExpenseAmountController.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มรายจ่ายประจำสำเร็จ')));
    }
  }

  void _deleteFixedExpense(int id) async {
    await IsarService.deleteFixedExpense(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายจ่ายประจำสำเร็จ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Adaptive colors for text fields
    final fieldFillColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest 
        : Colors.white;
    final fieldTextColor = theme.colorScheme.onSurface;
    final fieldLabelColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final fieldHintColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
        : Colors.grey;
    
    return Scaffold(
      appBar: AppBar(title: const Text('จดบัญชี / รายรับรายจ่าย')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Budget
            Card(
              elevation: 0,
              color: isDark 
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตั้งค่างบประมาณเดือนนี้ (คลังหลัก)', 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsSeparatorFormatter()],
                            style: TextStyle(
                              color: fieldTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'จำนวนเงิน (บาท)',
                              labelStyle: TextStyle(color: fieldLabelColor, fontSize: 14),
                              hintStyle: TextStyle(color: fieldHintColor),
                              filled: true,
                              fillColor: fieldFillColor,
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none, 
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary, 
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                          onPressed: _saveBudget,
                          child: Text('บันทึก', style: TextStyle(color: theme.colorScheme.onPrimary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'งบปัจจุบัน: ${formatNumberWithCommas(_currentBudget)} บาท', 
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Section 2: Fixed Expenses
            Text('รายจ่ายประจำ (หักเก็บอัตโนมัติ)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ระบบจะนำรายจ่ายส่วนนี้ไปหักออกจากงบให้เห็นว่าเหลือเงินใช้ได้จริงเท่าไหร่', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),

            // Add Fixed Expense Form
            Card(
              elevation: 0,
              color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fixedExpenseTitleController,
                      style: TextStyle(color: fieldTextColor),
                      decoration: InputDecoration(
                        labelText: 'ชื่อรายการ (เช่น กยศ., เน็ตบ้าน)',
                        labelStyle: TextStyle(color: fieldLabelColor),
                        filled: true,
                        fillColor: fieldFillColor,
                        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _fixedExpenseAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsSeparatorFormatter()],
                            style: TextStyle(color: fieldTextColor),
                            decoration: InputDecoration(
                              labelText: 'จำนวนเงิน',
                              labelStyle: TextStyle(color: fieldLabelColor),
                              filled: true,
                              fillColor: fieldFillColor,
                              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: fieldFillColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _fixedExpenseFrequency,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'monthly', child: Text('ต่อเดือน')),
                                  DropdownMenuItem(value: 'yearly', child: Text('ต่อปี')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _fixedExpenseFrequency = val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _saveFixedExpense,
                        icon: Icon(Icons.add, color: theme.colorScheme.onSecondary),
                        label: Text('เพิ่มรายจ่ายประจำ', style: TextStyle(color: theme.colorScheme.onSecondary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Fixed Expense List
            StreamBuilder<List<FixedExpenseModel>>(
              stream: IsarService.watchFixedExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final expenses = snapshot.data!;
                if (expenses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('ยังไม่มีรายการรายจ่ายประจำ', style: TextStyle(color: Colors.grey))),
                  );
                }

                double totalMonthlyToSave = 0;

                return Column(
                  children: [
                    ...expenses.map((e) {
                      totalMonthlyToSave += e.monthlyEquivalent;
                      final isYearly = e.frequency == 'yearly';
                      
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: isYearly 
                              ? Text('${formatNumberWithCommas(e.amount)} บาท/ปี\n(ตกเดือนละ ${formatNumberWithCommas(e.monthlyEquivalent)} บาท)', 
                                  style: TextStyle(color: theme.colorScheme.secondary))
                              : Text('${formatNumberWithCommas(e.amount)} บาท/เดือน'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteFixedExpense(e.id),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ยอดหักเก็บต่อเดือน:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${formatNumberWithCommas(totalMonthlyToSave)} บาท', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.error, fontSize: 16)
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // Section 3: Expense (General)
            Text('บันทึกรายจ่ายทั่วไป', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Text('เลือกหมวดหมู่:', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Wrap(
               spacing: 8.0,
               children: _categories.map((cat) {
                 return ChoiceChip(
                   label: Text(cat),
                   selected: _selectedCategory == cat,
                   onSelected: (selected) {
                     if (selected) setState(() => _selectedCategory = cat);
                   },
                 );
               }).toList(),
            ),
            
            if (_selectedCategory == 'อื่นๆ') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customTitleController,
                style: TextStyle(color: fieldTextColor),
                decoration: InputDecoration(
                  labelText: 'ระบุรายการค่าใช้จ่าย',
                  labelStyle: TextStyle(color: fieldLabelColor),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              style: TextStyle(
                color: fieldTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'จำนวนเงิน (บาท)',
                labelStyle: TextStyle(color: fieldLabelColor),
                hintStyle: TextStyle(color: fieldHintColor),
                prefixIcon: const Icon(Icons.money_off, color: Colors.redAccent),
              ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: _saveTransaction,
                child: const Text('บันทึกรายจ่าย', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
