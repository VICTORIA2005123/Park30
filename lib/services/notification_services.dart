import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  // Use this when a user starts parking
  static void showPersistentNotification(int id, String title, String body) async {
    NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'parking_channel',
        'Parking Updates',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true, // THIS KEEPS THE NOTIFICATION (Cannot be swiped away)
        autoCancel: false, // Does not disappear when clicked
        icon: '@mipmap/ic_launcher',
        // You can even add a progress bar or timer here
      ),
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  // Call this when the user finishes parking
  static void cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}