// lib/features/transactions/presentation/transaction_list_screen.dart
//
// REPLACE your existing transaction_list_screen.dart with this file.
// All data wiring (Riverpod provider, TransactionModel) is unchanged.
// Only the UI layer has been updated to the design system.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/transactions/data/transaction_model.dart';
import 'package:finance_app/features/transactions/provider/transaction_provider.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/widgets/reusable_widgets.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _filter = 'All';
  final _filters = [
    'All',
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(transactionProvider.notifier).loadTransactions();
    });
  }

  // ── Derived stats from live data ──────────────────────────────────────────
  double _totalExpenses(List<TransactionModel> txs) => txs
      .where((t) => t.type.toLowerCase() == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double _totalIncome(List<TransactionModel> txs) => txs
      .where((t) => t.type.toLowerCase() == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  List<TransactionModel> _filtered(List<TransactionModel> txs) {
    if (_filter == 'All') return txs;
    return txs
        .where((t) => t.category.toLowerCase() == _filter.toLowerCase())
        .toList();
  }

  // ── Group transactions by date label ──────────────────────────────────────
  Map<String, List<TransactionModel>> _grouped(List<TransactionModel> txs) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in txs) {
      String label = tx.date;
      try {
        final dt = DateTime.parse(tx.date);
        final now = DateTime.now();
        final diff = now.difference(dt).inDays;
        if (diff == 0)
          label = 'Today';
        else if (diff == 1)
          label = 'Yesterday';
        else
          label = '${dt.day} ${_month(dt.month)}';
      } catch (_) {}
      map.putIfAbsent(label, () => []).add(tx);
    }
    return map;
  }

  String _month(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  void _editTransaction(BuildContext context, TransactionModel tx) {
    // Open your edit screen / bottom sheet here.
    // Example:
    Navigator.pushNamed(context, '/add-transaction', arguments: tx);
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    TransactionModel tx,
  ) async {
    final id = tx.id;
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(transactionProvider.notifier).delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final filtered = _filtered(transactions);
    final grouped = _grouped(filtered);

    final totalExp = _totalExpenses(transactions);
    final totalInc = _totalIncome(transactions);

    return Scaffold(
      // ── AppBar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Companion',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text('Your finances, at a glance', style: tt.bodySmall),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),

      // ── FAB — opens type picker sheet first ──────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => TypePickerSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 26),
      ),

      body: transactions.isEmpty
          // ── Empty state ─────────────────────────────────────────────────
          ? _EmptyState()
          // ── Main content ────────────────────────────────────────────────
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Summary cards row ─────────────────────────────
                        SizedBox(
                          height: 144,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            children: [
                              SizedBox(
                                width: 168,
                                child: SummaryCard(
                                  label: 'Total Spent',
                                  value: '₹${totalExp.toStringAsFixed(0)}',
                                  subtitle:
                                      '${transactions.where((t) => t.type == 'expense').length} transactions',
                                  badgeText: 'Expenses',
                                  badgePositive: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 168,
                                child: SummaryCard(
                                  label: 'Total Income',
                                  value: '₹${totalInc.toStringAsFixed(0)}',
                                  subtitle:
                                      '${transactions.where((t) => t.type == 'income').length} entries',
                                  badgeText: 'Income',
                                  badgePositive: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 168,
                                child: SummaryCard(
                                  label: 'Balance',
                                  value:
                                      '₹${(totalInc - totalExp).toStringAsFixed(0)}',
                                  subtitle: 'Net position',
                                  badgeText: totalInc >= totalExp
                                      ? 'Positive'
                                      : 'Deficit',
                                  badgePositive: totalInc >= totalExp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Filter chips ──────────────────────────────────
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final f = _filters[i];
                              final active = _filter == f;
                              return GestureDetector(
                                onTap: () => setState(() => _filter = f),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: active
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.borderDark
                                                : AppColors.borderLight),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: active
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      color: active
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Grouped transaction list ────────────────────────────
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No transactions in this category',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entries = grouped.entries.toList();
                        final entry = entries[index];
                        return _GroupSection(
                          dateLabel: entry.key,
                          transactions: entry.value,
                          onEdit: _editTransaction,
                          onDelete: _deleteTransaction,
                        );
                      }, childCount: grouped.length),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GroupSection — date header + card of transactions for that day
// ─────────────────────────────────────────────────────────────────────────────
class _GroupSection extends StatelessWidget {
  final String dateLabel;
  final List<TransactionModel> transactions;
  final void Function(BuildContext context, TransactionModel tx)? onEdit;
  final void Function(BuildContext context, TransactionModel tx)? onDelete;

  const _GroupSection({
    required this.dateLabel,
    required this.transactions,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0.9,
            ),
          ),
        ),
        TransCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (int i = 0; i < transactions.length; i++) ...[
                TransactionTile(
                  merchant: transactions[i].merchant,
                  category: transactions[i].category,
                  note: transactions[i].note,
                  amount: transactions[i].amount,
                  type: transactions[i].type,
                  date: transactions[i].date,
                  onEdit: onEdit == null
                      ? null
                      : () => onEdit!(context, transactions[i]),
                  onDelete: onDelete == null
                      ? null
                      : () => onDelete!(context, transactions[i]),
                ),
                if (i < transactions.length - 1)
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add your first transaction',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
