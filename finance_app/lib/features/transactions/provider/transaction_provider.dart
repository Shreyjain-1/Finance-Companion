import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/transactions/data/transaction_repo.dart';
import 'package:finance_app/features/transactions/data/transaction_model.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:riverpod/legacy.dart';

final transactionRepoProvider = Provider((ref) {
  return TransactionRepository();
});

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository repo;

  TransactionNotifier(this.repo) : super([]);

  Future<void> loadTransactions() async {
    state = await repo.getTransactions();
  }

  Future<void> add(TransactionModel tx) async {
    await repo.addTransaction(tx);
    await loadTransactions();
  }

  Future<void> update(TransactionModel tx) async {
    await repo.updateTransaction(tx);
    state = await repo.getTransactions();
  }

  Future<void> delete(int id) async {
    await repo.deleteTransaction(id);
    state = await repo.getTransactions();
  }

  void deleteTransaction(int id) {
    state = state.where((tx) => tx.id != id).toList();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
      (ref) => TransactionNotifier(ref.read(transactionRepoProvider)),
    );
