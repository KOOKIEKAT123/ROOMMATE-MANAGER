enum ChoreFrequency { daily, weekly }

class Chore {
  final String id;
  final String title;
  final ChoreFrequency frequency;
  final String assignedTo; // memberId
  final bool completed;
  final DateTime createdAt;
  final DateTime? lastCompletedAt;
  final String householdId;

  Chore({
    required this.id,
    required this.title,
    required this.frequency,
    required this.assignedTo,
    required this.completed,
    required this.createdAt,
    this.lastCompletedAt,
    required this.householdId,
  });

  factory Chore.fromMap(Map<String, dynamic> data, String docId) {
    return Chore(
      id: docId,
      title: data['title'] ?? '',
      frequency: ChoreFrequency.values.firstWhere(
        (e) => e.toString() == 'ChoreFrequency.${data['frequency']}',
        orElse: () => ChoreFrequency.weekly,
      ),
      assignedTo: data['assignedTo'] ?? '',
      completed: data['completed'] ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastCompletedAt: (data['lastCompletedAt'] as dynamic)?.toDate(),
      householdId: data['householdId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'frequency': frequency.toString().split('.').last,
      'assignedTo': assignedTo,
      'completed': completed,
      'createdAt': createdAt,
      'lastCompletedAt': lastCompletedAt,
      'householdId': householdId,
    };
  }
}
