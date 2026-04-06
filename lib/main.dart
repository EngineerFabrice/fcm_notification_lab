import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );
  
  // Request permission
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
  print('Permission: ${settings.authorizationStatus}');
  
  // Get and print token
  String? token = await FirebaseMessaging.instance.getToken();
  print('=========================================');
  print('YOUR FCM TOKEN:');
  print(token);
  print('=========================================');
  
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Message received!');
    _showNotification(message);
  });
  
  runApp(const MyApp());
}

Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );
  const NotificationDetails details = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: message.notification?.title ?? 'New',
    body: message.notification?.body ?? '',
    notificationDetails: details,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _deviceToken = 'Tap button to get token';
  String _lastMessage = 'No messages yet';

  Future<void> _getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (!mounted) return;
    setState(() {
      _deviceToken = token ?? 'Failed';
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Token'),
        content: SelectableText(_deviceToken),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {
        _lastMessage = message.notification?.body ?? 'No body';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FCM Lab'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Device Token', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_deviceToken, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getToken,
                child: const Text('Get Device Token'),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const Text('Last Message', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(_lastMessage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}