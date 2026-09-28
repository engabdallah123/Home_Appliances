class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String? category;
  final DateTime date;
  final String? notes;
  final String syncStatus;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    this.category,
    required this.date,
    this.notes,
    this.syncStatus = 'Synced',
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      notes: json['notes'],
      syncStatus: json['syncStatus'] ?? 'Synced',
    );
  }
}
