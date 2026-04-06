// lib/features/transactions/presentation/add_transaction_screen.dart
//
// Three entry modes:
//   1. New manual entry  — arguments: {'initialType': 'expense'|'income'}
//   2. Edit existing     — arguments: TransactionModel
//   3. OCR pre-fill      — arguments: {'initialType': 'expense', 'prefill': BillScanResult}

import 'package:flutter/material.dart';
import 'package:finance_app/features/transactions/data/transaction_model.dart';
import 'package:finance_app/features/transactions/provider/transaction_provider.dart';
import 'package:finance_app/features/transactions/services/bill_ocr_services.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/widgets/reusable_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;
  final String initialType;
  final BillScanResult? prefill; // populated when coming from OCR

  const AddExpenseScreen({
    super.key,
    this.transaction,
    this.initialType = 'expense',
    this.prefill,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  String? _selectedCategory;
  String _type = 'expense';
  bool _wasPrefilled = false; // controls the auto-fill banner
  static const _expenseCategories = [
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Others',
  ];
  static const _incomeCategories = [
    'Salary',
    'Bonus',
    'Gifts',
    'Investments',
    'Profits',
    'Freelance',
    'Other Income',
  ];

  List<String> get _activeCategories =>
      _type == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      // ── Edit mode ─────────────────────────────────────────────────────────
      final tx = widget.transaction!;
      _merchantController.text = tx.merchant;
      _amountController.text = tx.amount.toString();
      _descriptionController.text = tx.note;
      _selectedCategory = tx.category;
      _type = tx.type;
    } else if (widget.prefill != null) {
      // ── OCR pre-fill mode ─────────────────────────────────────────────────
      final p = widget.prefill!;
      _type = widget.initialType;

      if (p.amount != null) {
        // Show as integer if whole number (e.g. 341), decimal if needed (341.50)
        final a = p.amount!;
        _amountController.text = (a == a.truncateToDouble())
            ? a.toInt().toString()
            : a.toStringAsFixed(2);
      }

      if (p.merchant != null) {
        _merchantController.text = p.merchant!;
      }

      _descriptionController.text = p.note;

      // Service now returns a validated category string directly.
      // Verify it exists in the expense list; fall back to 'Others'.
      _selectedCategory = _expenseCategories.firstWhere(
        (c) => c.toLowerCase() == p.category.toLowerCase(),
        orElse: () => 'Others',
      );

      _wasPrefilled = true;
    } else {
      // ── Fresh manual entry ────────────────────────────────────────────────
      _type = widget.initialType;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _resetFields() {
    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _merchantController.clear();
      _selectedCategory = null;
      _type = 'expense';
      _wasPrefilled = false;
    });
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final isEdit = widget.transaction != null;
    final tx = TransactionModel(
      id: isEdit ? widget.transaction!.id : null,
      amount: amount,
      type: _type,
      category:
          _selectedCategory ?? (_type == 'income' ? 'Other Income' : 'Others'),
      note: _descriptionController.text,
      date: DateTime.now().toIso8601String(),
      merchant: _merchantController.text,
    );
    if (isEdit) {
      ref.read(transactionProvider.notifier).update(tx);
    } else {
      ref.read(transactionProvider.notifier).add(tx);
    }
    Navigator.pop(context);
  }

  IconData _iconFor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'gifts':
        return Icons.redeem_rounded;
      case 'investments':
        return Icons.trending_up_rounded;
      case 'profits':
        return Icons.bar_chart_rounded;
      case 'freelance':
        return Icons.laptop_rounded;
      case 'other income':
        return Icons.attach_money_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Add transaction' : 'Edit transaction',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── OCR auto-fill banner ───────────────────────────────────────────
            if (_wasPrefilled) ...[
              _AutoFillBanner(
                isDark: isDark,
                onDismiss: () => setState(() => _wasPrefilled = false),
              ),
              const SizedBox(height: 16),
            ],

            // ── Type toggle ────────────────────────────────────────────────────
            TransCard(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _TypeToggleBtn(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    selected: _type == 'expense',
                    selectedColor: AppColors.expense,
                    onTap: () => setState(() {
                      _type = 'expense';
                      _selectedCategory = null;
                    }),
                  ),
                  _TypeToggleBtn(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    selected: _type == 'income',
                    selectedColor: AppColors.income,
                    onTap: () => setState(() {
                      _type = 'income';
                      _selectedCategory = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Amount ─────────────────────────────────────────────────────────
            TransCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '₹',
                    style: tt.headlineMedium?.copyWith(
                      color: _type == 'expense'
                          ? AppColors.expense
                          : AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: tt.headlineMedium?.copyWith(
                          color: AppColors.textMuted.withOpacity(0.4),
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Category ───────────────────────────────────────────────────────
            const SectionHeader(title: 'Category'),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Wrap(
                key: ValueKey(_type),
                spacing: 8,
                runSpacing: 8,
                children: _activeCategories
                    .map(
                      (cat) => CategoryChip(
                        label: cat,
                        icon: _iconFor(cat),
                        selected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Merchant / Source ──────────────────────────────────────────────
            TextField(
              key: ValueKey(_type),
              controller: _merchantController,
              decoration: InputDecoration(
                labelText: _type == 'income' ? 'Source' : 'Merchant',
              ),
            ),
            const SizedBox(height: 20),

            // ── Note ───────────────────────────────────────────────────────────
            const SectionHeader(title: 'Note'),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What was this for? (optional)',
              ),
            ),
            const SizedBox(height: 32),

            // ── Action buttons ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFields,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saveExpense,
                    child: Text(widget.transaction == null ? 'Save' : 'Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AutoFillBanner  — shown when form was pre-filled from a bill scan
// ─────────────────────────────────────────────────────────────────────────────
class _AutoFillBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onDismiss;
  const _AutoFillBanner({required this.isDark, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Fields auto-filled from your bill scan — review and adjust if needed.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypeToggleBtn
// ─────────────────────────────────────────────────────────────────────────────
class _TypeToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;
  const _TypeToggleBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? selectedColor : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? selectedColor : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
