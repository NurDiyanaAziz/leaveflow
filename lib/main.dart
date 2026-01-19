import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leaveflow/app/services/api.service.dart';
import 'package:leaveflow/app/services/sharedprefs.dart';
import 'package:leaveflow/app/views/leave.detail.screen.dart';
import 'package:leaveflow/app/views/manager_leave_details.dart';
import 'package:leaveflow/app/views/wrapper.dart';
import 'package:leaveflow/app/views/login.screen.dart';
import 'package:leaveflow/app/views/manager.screen.dart';
import 'package:leaveflow/app/views/employee.screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import this

// 1. Define the channel globally
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id - MUST MATCH BACKEND
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

  Future<void> _handleNotificationClick(RemoteMessage message) async {
  final data = message.data;
  final String? screen = data['screen'];
  final String? requestId = data['requestId'];

  if (screen == null || requestId == null) return;

  print("🔔 Notification Clicked: Going to $screen for ID $requestId");

  try {
    // 1. Fetch the full request details from API
    // You need to add this endpoint to your API Service if it doesn't exist
    // Or just reuse 'getAllRequests' and filter locally (easiest for MVP)
    final response = await api.getDio('/users/leave-request/$requestId'); 
    
    if (response != null && response.statusCode == 200) {
      final requestData = response.data['data']; // Ensure backend returns { data: { ... } }

      // 2. Navigate based on screen type
      if (screen == 'manager_detail') {
        Get.to(() => ManagerLeaveDetails(request: requestData));
      } else if (screen == 'employee_detail') {
        Get.to(() => LeaveDetailScreen(request: requestData));
      }
    }
  } catch (e) {
    print("Error fetching details for notification: $e");
    Get.snackbar("Error", "Could not load request details");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SharedPrefs.init();

  // 2. Create the Notification Channel on the device
  // This tells Android: "Hey, if any message comes for 'high_importance_channel', accept it!"
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 3. Request Permissions (Crucial for Android 13+)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // 1. Handle App Closed -> Open
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      _handleNotificationClick(message);
    }
  });

  // 2. Handle App Background -> Open
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LeaveFlow App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/manager', page: () => const ManagerScreen()),
        GetPage(name: '/employee', page: () => const EmployeeScreen()),
      ],
      home: Wrapper(),
    );
  }
}
