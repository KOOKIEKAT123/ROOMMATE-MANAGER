import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get messages stream for a household
  Stream<List<Message>> getMessages(String householdId) {
    return _firestore
        .collection('messages')
        .where('householdId', isEqualTo: householdId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Send a message
  Future<void> sendMessage({
    required String householdId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = Message(
      id: '',
      householdId: householdId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('messages').add(message.toMap());

    // Send notification
    await _notificationService.showChatNotification(
      senderName: senderName,
      message: text,
    );
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
  }
}
