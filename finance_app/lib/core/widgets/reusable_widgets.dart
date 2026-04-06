// lib/core/widgets/reusable_widgets.dart
//
// Drop-in reusable widgets for the finance UI.
// All widgets read colours from Theme / AppColors — no hardcoded values.
//
// Changes vs previous version:
//   • TypePickerSheet: Expense tap now opens BillInputSheet instead of
//     going straight to /add-transaction.
//   • BillInputSheet + _ScanOptionCard added at the bottom of this file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import 'package:finance_app/features/transactions/services/bill_ocr_services.dart';
import 'package:finance_app/features/transactions/services/receipt_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransCard
// ─────────────────────────────────────────────────────────────────────────────
class TransCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const TransCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final box = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: box);
    return box;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SummaryCard
// ─────────────────────────────────────────────────────────────────────────────
class SummaryCard extends StatelessWidget {
  final String label, value, subtitle, badgeText;
  final bool badgePositive;
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.badgeText,
    required this.badgePositive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final badgeColor = badgePositive ? AppColors.income : AppColors.expense;
    final badgeBg = badgePositive ? AppColors.incomeBg : AppColors.expenseBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: tt.bodySmall),
          Text(
            subtitle,
            style: tt.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TransactionTile
// ─────────────────────────────────────────────────────────────────────────────
class TransactionTile extends StatelessWidget {
  final String merchant, category, note, type, date;
  final double amount;
  final VoidCallback? onEdit, onDelete;

  const TransactionTile({
    super.key,
    required this.merchant,
    required this.category,
    required this.note,
    required this.amount,
    required this.type,
    required this.date,
    this.onEdit,
    this.onDelete,
  });

  bool get isExpense => type.toLowerCase() == 'expense';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _CategoryIcon(category: category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant.isNotEmpty ? merchant : category,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      style: tt.bodySmall?.copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            Text(
              '${isExpense ? '-' : '+'}₹${amount.toStringAsFixed(0)}',
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isExpense ? AppColors.expense : AppColors.income,
              ),
            ),
            
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) onEdit!();
                if (value == 'delete' && onDelete != null) onDelete!();
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(onEdit: onEdit, onDelete: onDelete),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String category;
  const _CategoryIcon({required this.category});

  static const Map<String, IconData> _icons = {
    'food': Icons.restaurant_rounded,
    'travel': Icons.directions_car_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'bills': Icons.receipt_long_rounded,
    'entertainment': Icons.movie_rounded,
    'health': Icons.favorite_rounded,
    'salary': Icons.account_balance_wallet_rounded,
    'bonus': Icons.card_giftcard_rounded,
    'gifts': Icons.redeem_rounded,
    'investments': Icons.trending_up_rounded,
    'profits': Icons.bar_chart_rounded,
    'freelance': Icons.laptop_rounded,
    'other income': Icons.attach_money_rounded,
    'others': Icons.category_rounded,
  };
  static const Map<String, Color> _colors = {
    'food': AppColors.catFood,
    'travel': AppColors.catTravel,
    'shopping': AppColors.catShopping,
    'bills': AppColors.catBills,
    'entertainment': AppColors.primary,
    'health': AppColors.expense,
    'salary': AppColors.income,
    'bonus': AppColors.warning,
    'gifts': AppColors.catShopping,
    'investments': AppColors.catTravel,
    'profits': AppColors.income,
    'freelance': AppColors.primary,
    'other income': AppColors.income,
    'others': AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final key = category.toLowerCase();
    final icon = _icons[key] ?? Icons.category_rounded;
    final color = _colors[key] ?? AppColors.textMuted;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  final VoidCallback? onEdit, onDelete;
  const _ActionSheet({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                onEdit!();
              },
            ),
          if (onDelete != null)
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.expense,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.expense),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete!();
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CategoryChip
// ─────────────────────────────────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bg = isDark ? AppColors.surfaceDark2 : AppColors.bgLight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader
// ─────────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AmountBadge
// ─────────────────────────────────────────────────────────────────────────────
class AmountBadge extends StatelessWidget {
  final double amount;
  final String type;
  const AmountBadge({super.key, required this.amount, required this.type});
  bool get isExpense => type.toLowerCase() == 'expense';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExpense ? AppColors.expenseBg : AppColors.incomeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${isExpense ? '-' : '+'}₹${amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isExpense ? AppColors.expense : AppColors.income,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TypePickerSheet
//
// FAB → this sheet → Expense taps open BillInputSheet
//                  → Income goes straight to /add-transaction
// ─────────────────────────────────────────────────────────────────────────────
class TypePickerSheet extends StatelessWidget {
  const TypePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TypePickerSheet(),
    );
  }

  void _onExpenseTap(BuildContext context) {
    Navigator.pop(context); // close TypePickerSheet
    BillInputSheet.show(context); // open scan/manual chooser
  }

  void _onIncomeTap(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/add-transaction',
      arguments: {'initialType': 'income'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'What would you like to add?',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text('Choose the transaction type to continue', style: tt.bodySmall),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TypeCard(
                  label: 'Expense',
                  description: 'Food, bills, shopping\nand more',
                  icon: Icons.arrow_upward_rounded,
                  accentColor: AppColors.expense,
                  bgColor: AppColors.expenseBg,
                  onTap: () => _onExpenseTap(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeCard(
                  label: 'Income',
                  description: 'Salary, bonus, gifts\nand more',
                  icon: Icons.arrow_downward_rounded,
                  accentColor: AppColors.income,
                  bgColor: AppColors.incomeBg,
                  onTap: () => _onIncomeTap(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label, description;
  final IconData icon;
  final Color accentColor, bgColor;
  final VoidCallback onTap;
  const _TypeCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final cardBg = isDark ? AppColors.surfaceDark2 : AppColors.bgLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(description, style: tt.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BillInputSheet
//
// Three choices after tapping "Expense":
//   1. Scan Bill    → camera  → on-device OCR → pre-fill form
//   2. From Gallery → gallery → on-device OCR → pre-fill form
//   3. Manual       → open form empty
// ─────────────────────────────────────────────────────────────────────────────
class BillInputSheet extends StatelessWidget {
  const BillInputSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => BillInputSheet(),
    );
  }

  Future<void> _startScan(BuildContext sheetCtx, ImageSource source) async {
    // Capture outer navigator context before closing the sheet
    final navCtx = Navigator.of(sheetCtx).context;
    Navigator.pop(sheetCtx);

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;
    if (!navCtx.mounted) return;

    _showLoadingOverlay(navCtx);

    BillScanResult? result;
    String? err;
    try {
      result = await ReceiptApiService.instance.scan(File(picked.path));
    } catch (e) {
      //err = 'Could not read the bill — please fill in manually.';
      print("OCR ERROR: $e");
      err = 'Backend error: ${e.toString()}';
    }

    if (!navCtx.mounted) return;
    Navigator.of(navCtx, rootNavigator: true).pop(); // dismiss loader

    if (err != null)
      ScaffoldMessenger.of(navCtx).showSnackBar(SnackBar(content: Text(err)));

    Navigator.pushNamed(
      navCtx,
      '/add-transaction',
      arguments: {
        'initialType': 'expense',
        if (result != null) 'prefill': result,
      },
    );
  }

  void _goManual(BuildContext sheetCtx) {
    final navCtx = Navigator.of(sheetCtx).context;
    Navigator.pop(sheetCtx);
    Navigator.pushNamed(
      navCtx,
      '/add-transaction',
      arguments: {'initialType': 'expense'},
    );
  }

  static void _showLoadingOverlay(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reading your bill…',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimDark
                        : AppColors.textPrimLight,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Analysing offline',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add Expense',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan a bill or enter the details yourself',
            style: tt.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryFaint,
                  title: 'Scan Bill',
                  subtitle: 'Take a photo\nto auto-fill',
                  isDark: isDark,
                  borderColor: border,
                  onTap: () => _startScan(context, ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.photo_library_rounded,
                  iconColor: AppColors.income,
                  iconBg: AppColors.incomeBg,
                  title: 'From Gallery',
                  subtitle: 'Pick an existing\nbill photo',
                  isDark: isDark,
                  borderColor: border,
                  onTap: () => _startScan(context, ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.edit_rounded,
                  iconColor: AppColors.warning,
                  iconBg: AppColors.warningBg,
                  title: 'Manual',
                  subtitle: 'Type in the\ndetails',
                  isDark: isDark,
                  borderColor: border,
                  onTap: () => _goManual(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 12,
                  color: AppColors.textMuted.withOpacity(0.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg, borderColor;
  final String title, subtitle;
  final bool isDark;
  final VoidCallback onTap;
  const _ScanOptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.surfaceDark2 : AppColors.bgLight;
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: tt.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
