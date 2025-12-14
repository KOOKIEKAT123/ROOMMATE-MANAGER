enum SplitMethod { equal, custom }

class Expense {
  final String id;
  final String description;
  final double amount;
  final String payerId;
  final SplitMethod splitMethod;
  final Map<String, double> splits; // memberId -> amount
  final List<String> category;
  final DateTime date;
  final String householdId;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.payerId,
    required this.splitMethod,
    required this.splits,
    required this.category,
    required this.date,
    required this.householdId,
  });

  factory Expense.fromMap(Map<String, dynamic> data, String docId) {
    return Expense(
      id: docId,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      payerId: data['payerId'] ?? '',
      splitMethod:
          SplitMethod.values.firstWhere(
            (e) => e.toString() == 'SplitMethod.${data['splitMethod']}',
            orElse: () => SplitMethod.equal,
          ),
      splits: Map<String, double>.from(
        (data['splits'] as Map?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      ),
      category: List<String>.from(data['category'] ?? []),
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      householdId: data['householdId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'payerId': payerId,
      'splitMethod': splitMethod.toString().split('.').last,
      'splits': splits,
      'category': category,
      'date': date,
      'householdId': householdId,
    };
  }
}
