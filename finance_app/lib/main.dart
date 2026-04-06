import 'package:finance_app/features/transactions/presentation/add_transaction_screen.dart';
import 'package:finance_app/features/transactions/presentation/transaction_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/transactions/data/transaction_model.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/transactions',
      routes: {
        '/transactions': (context) => const TransactionListScreen(),
        '/add-transaction': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          // ✅ Edit mode
          if (args is TransactionModel) {
            return AddExpenseScreen(transaction: args);
          }

          // ✅ OCR / Prefill mode
          if (args is Map && args['prefill'] != null) {
            return AddExpenseScreen(
              initialType: args['initialType'] ?? 'expense',
              prefill: args['prefill'], // 👈 THIS IS THE KEY FIX
            );
          }

          // ✅ Normal add
          final type =
              (args is Map ? args['initialType'] as String? : null) ??
              'expense';

          return AddExpenseScreen(initialType: type);
        },
      },
    );
  }
}
