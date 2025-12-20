class Member {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  Member({required this.id, required this.name, required this.email, required this.createdAt});

  factory Member.fromMap(Map<String, dynamic> data, String docId) {
    return Member(
      id: docId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'createdAt': createdAt};
  }
}
