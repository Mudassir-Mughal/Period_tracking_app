import 'package:calender_app/screens/pregnancysetupscreen.dart';
import 'package:calender_app/screens/question1.dart';
import 'package:calender_app/screens/question2.dart';
import 'package:calender_app/screens/reminder.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Keep all your existing methods (initState, _loadSettings, _updatePregnancyMode, _resetData)
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
    modeChangeNotifier.notify();
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
        title: Text(
          "Reset Data",
          style: GoogleFonts.poppins(
              color: Color(0xFFFD6BA2),
              fontWeight: FontWeight.bold
          ),
        ),
        content: Text(
          "Are you sure you want to reset your data?",
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Color(0xFFFD6BA2)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetData();
            },
            child: Text(
              "Yes, Reset",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFFFD6BA2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFFFD6BA2),
                    size: 20,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.grey[200],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Icon(Icons.chevron_left ,color: Colors.black , size: 30,),
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSettingItem(
            icon: Icons.water_drop_outlined,
            title: "Period Length",
            subtitle: "$periodLength days",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardStep1(fromSettings: true)),
              );
              _loadSettings();
            },
          ),
          _buildSettingItem(
            icon: Icons.calendar_today_outlined,
            title: "Cycle Length",
            subtitle: "$cycleLength days",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OnboardStep2(periodLength: periodLength, fromSettings: true),
                ),
              );
              _loadSettings();
            },
          ),
          _buildSettingItem(
            icon: Icons.color_lens_outlined,
            title: "Themes",
            onTap: () {
              // Add themes functionality
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: "Reminders",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.pregnant_woman_outlined,
            title: "Pregnancy Mode",
            subtitle: isPregnancyMode ? "On" : "Off",
            onTap: () async {
              if (!isPregnancyMode) {
                await _updatePregnancyMode(true);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PregnancySetupScreen()),
                );
                if (result == true) {
                  await _updatePregnancyMode(true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Pregnancy mode turned ON.",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Color(0xFFFD6BA2),
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Pregnancy mode turned OFF.",
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.pinkAccent,
                  ),
                );
              }
            },
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy",
            onTap: () {
              // Add privacy functionality
            },
          ),
          _buildSettingItem(
            icon: Icons.feedback_outlined,
            title: "Feed back",
            onTap: () {
              // Add feedback functionality
            },
          ),
          _buildSettingItem(
            icon: Icons.share_outlined,
            title: "Share with friends",
            showDivider: false,
            onTap: () {
              // Add share functionality
            },
          ),
          SizedBox(height: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton(
              onPressed: _showResetConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFD6BA2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                "Reset App Data",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}