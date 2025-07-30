import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash.dart';
import 'screens/question1.dart';
import 'screens/bottomnaviagtor.dart'; // add this
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

Future<void> initializeNotifications() async {
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'reminder_channel',
      channelName: 'Reminder Notifications',
      channelDescription: 'Notification channel for reminders',
      defaultColor: Colors.pink,
      ledColor: Colors.white,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      playSound: true,
      enableVibration: true,
    ),
  ], debug: true);
}

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await initializeNotifications();
  await requestNotificationPermission();
  tz.initializeTimeZones();

  // Initialize theme provider
  final themeProvider = ThemeProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Add this line
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final theme = themeProvider.currentTheme;

        return MaterialApp(
          title: 'Period Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: theme.backgroundColor,
            primaryColor: theme.accentColor,
            colorScheme: ColorScheme.light(
              primary: theme.accentColor,
              secondary: theme.accentColor,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
