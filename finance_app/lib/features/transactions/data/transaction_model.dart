class TransactionModel {
  final int? id;
  final double amount;
  final String type; // income / expense
  final String category;
  final String note;
  final String date;
  final String merchant;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.date,
    required this.merchant,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'date': date,
      'merchant': merchant,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      note: map['note'],
      date: map['date'],
      merchant: map['merchant'],
    );
  }
}