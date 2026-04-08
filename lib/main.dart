import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  await _showNotification(message);
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
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
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('Permission: ${settings.authorizationStatus}');
  
  // Create notification channel for Android 8.0+
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is for important notifications',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  
  // Get and print token
  String? token = await FirebaseMessaging.instance.getToken();
  debugPrint('=========================================');
  debugPrint('YOUR FCM TOKEN:');
  debugPrint(token);
  debugPrint('=========================================');
  
  runApp(const MyApp());
}

// ========== ADD THIS FUNCTION FOR POPUP ==========
void _showPopupDialog(RemoteMessage message) {
  // Get context from app key
  final BuildContext? context = myAppKey.currentContext;
  if (context == null) return;
  
  String title = message.notification?.title ?? 'New Notification';
  String body = message.notification?.body ?? 'You have a new message';
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.blue, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    },
  );
}
// ================================================

final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String _deviceToken = 'Tap button to get token';
  String _lastMessage = 'My name from fabrice';
  String _lastTitle = '';

  void updateLastMessage(String body, String title) {
    if (mounted) {
      setState(() {
        _lastMessage = body.isNotEmpty ? body : 'No body';
        _lastTitle = title;
      });
    }
  }

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
    
    // Handle foreground messages (now that widget is built)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Foreground message received!');
      
      // Show system notification
      _showNotification(message);
      
      // SHOW POPUP DIALOG
      _showPopupDialog(message);
      
      // Update UI
      setState(() {
        _lastMessage = message.notification?.body ?? '';
        _lastTitle = message.notification?.title ?? '';
      });
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 App opened from notification');
      setState(() {
        _lastMessage = message.notification?.body ?? 'No body';
        _lastTitle = message.notification?.title ?? '';
      });
      _showNotification(message);
      _showPopupDialog(message);  // Show popup when opened from background
    });
    
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 App opened from terminated state');
        setState(() {
          _lastMessage = message.notification?.body ?? 'No body';
          _lastTitle = message.notification?.title ?? '';
        });
      }
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
          centerTitle: true,
          
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Token Section
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
              
              // ========== DISPLAY RECEIVED MESSAGE INSIDE APP UI ==========
              const Text('Last Received Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastTitle.isNotEmpty)
                      Text(
                        '📩 $_lastTitle',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _lastMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📱 Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('✓ Popup appears when notification arrives'),
                    Text('✓ Message displayed in green box above'),
                    Text('✓ System notification in notification shade'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}