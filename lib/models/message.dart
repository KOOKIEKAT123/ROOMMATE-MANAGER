class Message {
  final String id;
  final String householdId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.householdId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> data, String docId) {
    return Message(
      id: docId,
      householdId: data['householdId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'householdId': householdId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
