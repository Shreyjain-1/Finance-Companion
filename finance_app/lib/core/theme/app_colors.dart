import 'package:flutter/material.dart';

class AppColors {
  // 1. Primary
  static const primary = Color(0xFF7B6FD4);
  static const primaryLight = Color(0xFFA89EE8);
  static const primaryFaint = Color(0x1A7B6FD4);

  // 2. Secondary / accent
  static const secondary = Color(0xFFA89EE8);

  // 3. Backgrounds
  static const bgDark = Color(0xFF0D0D12);
  static const bgLight = Color(0xFFF8F7FF);

  // 4. Surface / card
  static const surfaceDark = Color(0xFF13131A);
  static const surfaceLight = Color(0xFFEEEDFB);
  static const surfaceDark2 = Color(0xFF1E1E28); // input fill on dark
  static const inputBorderDark = Color(0xFF3A3750);

  // 5. Text
  static const textPrimDark = Color(0xFFE8E6F0);
  static const textSecDark = Color(0xFFD0CDE8);
  static const textPrimLight = Color(0xFF1A1825);
  static const textSecLight = Color(0xFF4A4660);
  static const textMuted = Color(0xFF6B6880);

  // 6. Finance semantic
  static const income = Color(0xFF3DBB7A);
  static const incomeBg = Color(0x1A3DBB7A);
  static const expense = Color(0xFFE8504A);
  static const expenseBg = Color(0x1AE8504A);
  static const warning = Color(0xFFF5A623);
  static const warningBg = Color(0x1AF5A623);

  // 7. Dividers
  static const dividerDark = Color(0xFF2A2A38);
  static const dividerLight = Color(0xFFE0DEEF);
  static const borderDark = Color(0xFF2A2A38);
  static const borderLight = Color(0xFFE0DEEF);

  // 8. Splash
  static final splash = primary.withOpacity(0.15);

  // 9. Expense category colors
  static const catFood = Color(0xFF63D290);
  static const catTravel = Color(0xFF6BBBFF);
  static const catShopping = Color(0xFFFF6B9D);
  static const catBills = Color(0xFFFFB86B);
  static const catEntertainment = Color(0xFFC4BAFF);
  static const catHealth = Color(0xFFFF6B6B);
  static const catOthers = Color(0xFF8882A0);

  // 10. Income category colors (distinct greener/warmer palette)
  static const catSalary = Color(0xFF3DBB7A); // mint green
  static const catBonus = Color(0xFF00C9A7); // teal
  static const catGifts = Color(0xFFA89EE8); // soft purple
  static const catInvestments = Color(0xFF4FC3F7); // sky blue
  static const catProfits = Color(0xFFF5A623); // amber
  static const catFreelance = Color(0xFF81C784); // sage green
  static const catOtherIncome = Color(0xFF8882A0); // slate

  /// Returns the color for any category string — works for both
  /// expense and income categories.
  static Color forCategory(String category) {
    switch (category.toLowerCase()) {
      // ── Expense ──
      case 'food':
        return catFood;
      case 'travel':
        return catTravel;
      case 'shopping':
        return catShopping;
      case 'bills':
        return catBills;
      case 'entertainment':
        return catEntertainment;
      case 'health':
        return catHealth;
      // ── Income ──
      case 'salary':
        return catSalary;
      case 'bonus':
        return catBonus;
      case 'gifts':
        return catGifts;
      case 'investments':
        return catInvestments;
      case 'profits':
        return catProfits;
      case 'freelance':
        return catFreelance;
      case 'other income':
        return catOtherIncome;
      default:
        return catOthers;
    }
  }
}
