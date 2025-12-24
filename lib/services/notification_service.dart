import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // 1. Local Notifications Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Request permissions (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // 2. FCM Setup
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get Token (for debugging)
    final token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        showNotification(
          id: message.hashCode, 
          title: message.notification!.title ?? 'New Notification', 
          body: message.notification!.body ?? '',
        );
      }
    });
    
    // Background Handler Registration happens in main.dart usually, 
    // but the handler function is defined in this file (at bottom).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'parking_channel',
      'Parking Notifications',
      channelDescription: 'Notifications for parking session updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleBookingNotifications({
    required String bookingId,
    required DateTime endTime,
  }) async {
    // Generate an ID based on hash of bookingId
    final int notificationId = bookingId.hashCode;

    // 1. Schedule "10 Minutes Remaning"
    final DateTime warningTime = endTime.subtract(const Duration(minutes: 10));
    if (warningTime.isAfter(DateTime.now())) {
      await _schedule(
        id: notificationId,
        title: 'Parking Ending Soon!',
        body: 'Your parking session expires in 10 minutes.',
        scheduledTime: warningTime,
      );
    }

    // 2. Schedule "Time Is Up"
    if (endTime.isAfter(DateTime.now())) {
      await _schedule(
        id: notificationId + 1, // Offset ID for second notification
        title: 'Parking Session Expired',
        body: 'Your parking time is up. Please move your vehicle or extend.',
        scheduledTime: endTime,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'parking_channel',
          'Parking Notifications',
          channelDescription: 'Notifications for parking session updates',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotifications(String bookingId) async {
    final int notificationId = bookingId.hashCode;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    await flutterLocalNotificationsPlugin.cancel(notificationId + 1);
  }
}

// Background Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  print("Handling a background message: ${message.messageId}");
}
