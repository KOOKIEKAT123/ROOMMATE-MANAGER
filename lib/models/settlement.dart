enum PaymentMethod { cash, bkash, bankTransfer }

class Settlement {
  final String id;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final PaymentMethod method;
  final String? notes;
  final DateTime date;
  final String householdId;

  Settlement({
    required this.id,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.method,
    this.notes,
    required this.date,
    required this.householdId,
  });

  factory Settlement.fromMap(Map<String, dynamic> data, String docId) {
    return Settlement(
      id: docId,
      fromMemberId: data['fromMemberId'] ?? '',
      toMemberId: data['toMemberId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${data['method']}',
        orElse: () => PaymentMethod.cash,
      ),
      notes: data['notes'],
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      householdId: data['householdId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromMemberId': fromMemberId,
      'toMemberId': toMemberId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'notes': notes,
      'date': date,
      'householdId': householdId,
    };
  }
}
