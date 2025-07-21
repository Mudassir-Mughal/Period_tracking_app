import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question3.dart';
import 'question1.dart';

class OnboardStep2 extends StatefulWidget {
  final bool fromSettings;
  final int periodLength;
  const OnboardStep2({super.key, required this.periodLength, this.fromSettings = false});

  @override
  State<OnboardStep2> createState() => _OnboardStep2State();
}

class _OnboardStep2State extends State<OnboardStep2> {
  int cycleLength = 28;
  late FixedExtentScrollController _scrollController;

  final Color primaryPink = const Color(0xFFFF4F8B);
  final Color lightPink = const Color(0xFFFF80AB);

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: cycleLength - 16);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EC), // Light pink background as screenshot
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top navigation row with back button and progress indicator
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
                      splashRadius: 22,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    // Progress indicator centered
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: SizedBox(
                            width: 180, // progress bar width
                            child: LinearProgressIndicator(
                              value: 2 / 3,
                              backgroundColor: lightPink.withOpacity(0.2),
                              color: primaryPink,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90),
              // Question Text
              Center(
                child: Text(
                  'How many days does your cycle usually last?',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: primaryPink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 90),
              // Centered ListWheel
              Center(
                child: Container(
                  height: 120,
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 48,
                    diameterRatio: 1.2,
                    perspective: 0.003,
                    squeeze: 1.18,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (value) {
                      setState(() {
                        cycleLength = value + 16;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 30, // 16 to 99
                      builder: (context, index) {
                        final isSelected = cycleLength == index + 16;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            height: 48,
                            decoration: isSelected
                                ? BoxDecoration(
                              color: primaryPink.withOpacity(0.32),
                              borderRadius: BorderRadius.circular(14),
                            )
                                : null,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Always center the number
                                Center(
                                  child: Text(
                                    '${index + 16}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      color: Colors.black,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                // Show "Days" only if selected, aligned to right
                                if (isSelected)
                                  Positioned(
                                    right: 20,
                                    child: Text(
                                      'Days',
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('cycleLength', cycleLength);
                      if (widget.fromSettings) {
                        Navigator.pop(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OnboardStep3(
                              periodLength: widget.periodLength,
                              cycleLength: cycleLength,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: primaryPink,
                    ),
                    child: Text(
                      'Next',
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
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}