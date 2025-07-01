import 'package:calender_app/screens/pregnancysetupscreen.dart';
import 'package:calender_app/screens/question1.dart';
import 'package:calender_app/screens/question2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int cycleLength = 28;
  int periodLength = 5;
  bool isPregnancyMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cycleLength = prefs.getInt('cycleLength') ?? 28;
      periodLength = prefs.getInt('periodLength') ?? 5;
      isPregnancyMode = prefs.getBool('pregnancyMode') ?? false;
    });
  }

  Future<void> _updatePregnancyMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pregnancyMode', value);
    setState(() {
      isPregnancyMode = value;
    });
    modeChangeNotifier.notify(); // <-- Notifies all listening pages
  }

  Future<void> _resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardStep1()),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Reset Data",
          style: TextStyle(color: Color(0xFFFD6BA2), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to reset your data?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFFFD6BA2))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetData();
            },
            child: const Text("Yes, Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainPink = Color(0xFFFD6BA2);
    final lightPink = Color(0xFFF9F3FF);
    final accentPurple = Color(0xFFB35AFF);

    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: mainPink,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: mainPink),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F3FF), Color(0xFFFDE5F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: mainPink.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔘 Pregnancy Mode Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pregnant_woman, color: mainPink),
                            const SizedBox(width: 14),
                            const Text(
                              "Pregnancy Mode",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: mainPink,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isPregnancyMode,
                          activeColor: mainPink,
                          onChanged: (value) async {
                            if (value) {
                              await _updatePregnancyMode(true);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PregnancySetupScreen()),
                              );
                              if (result == true) {
                                await _updatePregnancyMode(true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Pregnancy mode turned ON."),
                                    backgroundColor: mainPink,
                                  ),
                                );
                              } else {
                                await _updatePregnancyMode(false);
                              }
                            } else {
                              await _updatePregnancyMode(false);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('pregnancyStartDate');
                              await prefs.remove('pregnancyDisplayOption');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Pregnancy mode turned OFF."),
                                  backgroundColor: Colors.pinkAccent,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// 💧 Period Length
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OnboardStep1(fromSettings: true)),
                        );
                        _loadSettings();
                      },
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: mainPink.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: const Icon(Icons.water_drop, color: mainPink, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            "Period Length: ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: mainPink,
                            ),
                          ),
                          Text(
                            "$periodLength days",
                            style: const TextStyle(
                              fontSize: 18,
                              color: mainPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// 📅 Cycle Length
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OnboardStep2(periodLength: periodLength, fromSettings: true),
                          ),
                        );
                        _loadSettings();
                      },
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: accentPurple.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.calendar_month, color: accentPurple, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            "Cycle Length: ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: accentPurple,
                            ),
                          ),
                          Text(
                            "$cycleLength days",
                            style: TextStyle(
                              fontSize: 18,
                              color: accentPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),

                    Divider(
                      color: Colors.grey.withOpacity(0.13),
                      thickness: 1.5,
                      height: 14,
                    ),
                    const SizedBox(height: 36),

                    /// 🔄 Reset Button
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.restart_alt, color: Colors.white),
                        label: const Text(
                          "Reset App Data",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainPink,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: mainPink.withOpacity(0.19),
                        ),
                        onPressed: _showResetConfirmation,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}