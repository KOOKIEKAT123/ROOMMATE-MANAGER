import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationService._internal() {
    _initializeNotifications();
  }

  factory NotificationService() {
    return _instance;
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show notification for expense added
  Future<void> showExpenseNotification({
    required String title,
    required String description,
    required String amount,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'expense_channel',
      'Expense Notifications',
      channelDescription: 'Notifications for expense activities',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().hashCode,
      title,
      '$description - $amount',
      platformChannelSpecifics,
    );
  }

  // Show notification for chore deadline
  Future<void> showChoreDeadlineNotification({
    required String title,
    required String choreTitle,
    required String assignee,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'chore_channel',
      'Chore Notifications',
      channelDescription: 'Notifications for chore deadlines',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().hashCode,
      title,
      '$choreTitle assigned to $assignee',
      platformChannelSpecifics,
    );
  }

  // Show notification for settlement
  Future<void> showSettlementNotification({required String title, required String message}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'settlement_channel',
      'Settlement Notifications',
      channelDescription: 'Notifications for payments and settlements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(DateTime.now().hashCode, title, message, platformChannelSpecifics);
  }

  // Show notification for member joined
  Future<void> showMemberJoinedNotification({required String memberName}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'member_channel',
      'Member Notifications',
      channelDescription: 'Notifications for member activities',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().hashCode,
      'New Member',
      '$memberName joined the household',
      platformChannelSpecifics,
    );
  }

  // Schedule notification for chore deadline
  Future<void> scheduleChoreDeadlineNotification({
    required String choreTitle,
    required String assignee,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final daysUntilDeadline = deadline.difference(now).inDays;

    // Send reminder 1 day before deadline
    if (daysUntilDeadline == 1) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'chore_deadline_channel',
        'Chore Deadline Reminders',
        channelDescription: 'Reminders for upcoming chore deadlines',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().hashCode,
        '⏰ Chore Deadline Tomorrow',
        '$choreTitle is due tomorrow for $assignee',
        platformChannelSpecifics,
      );
    }
  }
}
