import 'package:finance_app/data/db_helper.dart';
import 'package:finance_app/features/transactions/data/transaction_model.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper();

  Future<void> addTransaction(TransactionModel tx) async {
    final db = await dbHelper.database;
    await db.insert('transactions', tx.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await dbHelper.database;
    final result = await db.query('transactions', orderBy: 'date DESC');

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final db = await dbHelper.database;

    await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await dbHelper.database;

    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
