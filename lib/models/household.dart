class Household {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final List<String> categories;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.categories,
    required this.createdAt,
  });

  factory Household.fromMap(Map<String, dynamic> data, String docId) {
    return Household(
      id: docId,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      categories: List<String>.from(data['categories'] ?? ['Food', 'Utilities', 'Rent', 'Entertainment', 'Other']),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'ownerId': ownerId, 'memberIds': memberIds, 'categories': categories, 'createdAt': createdAt};
  }
}
