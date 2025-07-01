import 'package:flutter/material.dart';
import 'screens/splash.dart';
import 'screens/question1.dart';
import 'screens/bottomnaviagtor.dart'; // add this

void main() {
  runApp(const PeriodTrackerApp());
}

class PeriodTrackerApp extends StatelessWidget {
  const PeriodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
      ),
        home: SplashScreen(),


    );
  }
}
