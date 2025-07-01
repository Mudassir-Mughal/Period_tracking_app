import 'package:calender_app/screens/bottomnaviagtor.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'question1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Color primaryPink = const Color(0xFFFF4F8B);
  final Color lightPink = const Color(0xFFFF80AB);

  @override
  void initState() {
    super.initState();
    checkUserSetup();
  }

  Future<void> checkUserSetup() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.containsKey('periodLength') &&
        prefs.containsKey('cycleLength') &&
        prefs.containsKey('lastPeriodDate');

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hasData ? const MainScreen() : const OnboardStep1(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon or Logo (optional)
            Icon(Icons.calendar_month, color: primaryPink, size: 80),
            const SizedBox(height: 20),
            Text(
              'Period Tracker',
              style: TextStyle(
                fontSize: 24,
                color: primaryPink,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.pinkAccent,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
