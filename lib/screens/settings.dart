import 'package:calender_app/screens/pregnancysetupscreen.dart';
import 'package:calender_app/screens/question1.dart';
import 'package:calender_app/screens/question2.dart';
import 'package:calender_app/screens/reminder.dart';
import 'package:calender_app/screens/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'notifier.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int cycleLength = 28;
  int periodLength = 5;
  bool isPregnancyMode = false;
  final Color primaryPink = const Color(0xFFFF4F8B);

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
            fontWeight: FontWeight.bold,
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
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4), // reduced gap
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFD6BA2).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFFD6BA2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Color(0xFFFD6BA2), size: 18),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPregnancySwitchItem() {
    return _buildSettingItem(
      icon: Icons.pregnant_woman_outlined,
      title: "Pregnancy Mode",
      subtitle: isPregnancyMode ? "On" : "Off",
      onTap: () async {
        // no tap action, handled by switch
      },
      trailing: Switch.adaptive(
        value: isPregnancyMode,
        onChanged: (value) async {
          if (value) {
            // Turning ON
            await _updatePregnancyMode(true);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PregnancySetupScreen()),
            );
            if (result != true) {
              // user cancelled
              await _updatePregnancyMode(false);
            }
          } else {
            // Turning OFF
            await _updatePregnancyMode(false);
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('pregnancyStartDate');
            await prefs.remove('pregnancyDisplayOption');
          }
          _loadSettings();
        },
        activeColor: Color(0xFFFD6BA2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      backgroundColor: Color(0xFFFFE6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
        leadingWidth: 50,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 4),
        children: [
          _buildSettingItem(
            icon: Icons.water_drop_outlined,
            title: "Period Length",
            subtitle: "$periodLength days",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OnboardStep1(fromSettings: true),
                ),
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
                  builder: (_) => OnboardStep2(
                    periodLength: periodLength,
                    fromSettings: true,
                  ),
                ),
              );
              _loadSettings();
            },
          ),
          _buildSettingItem(
            icon: Icons.color_lens_outlined,
            title: "Themes",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeScreen()),
              );
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
          _buildPregnancySwitchItem(),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () {
              // Add privacy functionality
            },
          ),
          _buildSettingItem(
            icon: Icons.feedback_outlined,
            title: "Feedback",
            onTap: () {
              launchUrl(Uri.parse('mailto:mughalmudassir33@gmail.com'));
            },
          ),
          _buildSettingItem(
            icon: Icons.share_outlined,
            title: "Share with friends",
            onTap: () {
              const message = 'Check out this awesome app: your link';
              Share.share(message);
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showResetConfirmation,

              style: ElevatedButton.styleFrom(
              backgroundColor: primaryPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              "Reset",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
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
