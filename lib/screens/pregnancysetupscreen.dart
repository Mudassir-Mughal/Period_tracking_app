import 'package:calender_app/screens/bottomnaviagtor.dart';
import 'package:calender_app/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PregnancySetupScreen extends StatefulWidget {
  const PregnancySetupScreen({super.key});

  @override
  State<PregnancySetupScreen> createState() => _PregnancySetupScreenState();
}

class _PregnancySetupScreenState extends State<PregnancySetupScreen> {
  DateTime selectedStartDate = DateTime.now();
  int selectedOption = 0;

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDateStr = prefs.getString('pregnancyStartDate');
    final storedOption = prefs.getInt('pregnancyDisplayOption');

    if (storedDateStr != null) {
      setState(() {
        selectedStartDate = DateTime.parse(storedDateStr);
      });
    }
    if (storedOption != null) {
      setState(() {
        selectedOption = storedOption;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainPink = const Color(0xFFFD6BA2);
    final media = MediaQuery.of(context);

    // Responsive values
    double width = media.size.width;
    double height = media.size.height;
    double safeTop = media.padding.top;
    double safeBottom = media.padding.bottom;

    double horizontalPadding = width * 0.05;
    double verticalSpacing = height * 0.025;
    double babyImageWidth = width * 0.5;
    double babyImageHeight = height * 0.16;
    double buttonPadding = width * 0.10;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF3F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF3F7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Bottom left image - always at the bottom left, never scales
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              'assets/bottomleft.png',
              width: 120,
              // If you want to use native size, leave width/height out.
              // To scale a bit on big screens, you could set max width, e.g.:
              // width: width * 0.32,
              // fit: BoxFit.contain,
            ),
          ),
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: safeBottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: verticalSpacing),
                      // Baby image and congratulations
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/baby.png',
                              width: babyImageWidth.clamp(140, 240),
                              height: babyImageHeight.clamp(80, 140),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: verticalSpacing * 0.6),
                            Text(
                              '🎉 Congratulations!',
                              style: GoogleFonts.poppins(
                                color: mainPink,
                                fontSize: width * 0.07,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: verticalSpacing * 0.3),
                            Text(
                              'Count down the days until your baby arrives!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: width * 0.03,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: verticalSpacing * 0.7),

                      // Estimated Start
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: verticalSpacing * 0.6,
                          horizontal: width * 0.04,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          title: Text(
                            "Estimated start of gestation",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy').format(selectedStartDate),
                            style: GoogleFonts.poppins(
                              color: mainPink,
                              fontSize: width * 0.035,
                            ),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedStartDate,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: mainPink,
                                      onPrimary: Colors.white,
                                      onSurface: mainPink,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: mainPink,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                selectedStartDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 10),

                      Text(
                        "Display on the homepage",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: width * 0.039,
                        ),
                      ),
                      SizedBox(height: verticalSpacing * 0.4),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<int>(
                              title: Text(
                                "0W1D since pregnancy",
                                style: GoogleFonts.poppins(
                                  fontSize: width * 0.037,
                                ),
                              ),
                              value: 0,
                              groupValue: selectedOption,
                              onChanged: (val) => setState(() => selectedOption = val!),
                              activeColor: mainPink,
                            ),
                            RadioListTile<int>(
                              title: Text(
                                "Countdown (days left)",
                                style: GoogleFonts.poppins(
                                  fontSize: width * 0.037,
                                ),
                              ),
                              value: 1,
                              groupValue: selectedOption,
                              onChanged: (val) => setState(() => selectedOption = val!),
                              activeColor: mainPink,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: verticalSpacing * 0.7),

                      // Save Button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('pregnancyMode', true);
                              await prefs.setString('pregnancyStartDate', selectedStartDate.toIso8601String());
                              await prefs.setInt('pregnancyDisplayOption', selectedOption);

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MainScreen(initialTab: 0)),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pregnancy mode On')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainPink,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: verticalSpacing * 0.7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Save',
                              style: GoogleFonts.poppins(
                                fontSize: width * 0.052,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}