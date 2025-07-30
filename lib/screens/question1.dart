import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question2.dart';

class OnboardStep1 extends StatefulWidget {
  final bool fromSettings;
  const OnboardStep1({super.key, this.fromSettings = false});

  @override
  State<OnboardStep1> createState() => _OnboardStep1State();
}

class _OnboardStep1State extends State<OnboardStep1> {
  int selectedDay = 5;

  final Color primaryPink = const Color(0xFFFF4F8B);
  final Color lightPink = const Color(0xFFFF80AB);

  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EC), // Light pink like screenshot
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top navigation row
              SizedBox(
                height: 50,
                child: Row(

                  children: [

                    // Centered, small progress indicator
                    Expanded(
                      child: Center(
                      child: Padding(
                           padding: const EdgeInsets.only(left: 30),
                          child: SizedBox(
                          width: 180, // Smaller progress indicator
                          child: LinearProgressIndicator(
                            value: 1 / 3,
                            backgroundColor: lightPink.withOpacity(0.2),
                            color: primaryPink,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),),
                    ),
                    // Gap between progress indicator and Skip

                    // Skip text


                  ],
                ),
              ),
              // Vertical gap after top navigation row
              const SizedBox(height: 90),

              // Question
              Center(
                child: Text(
                  'How many days does your period usually last?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryPink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Increased gap between question and picker
              const SizedBox(height: 90),

              // Picker UI (centered with height showing 3 items)
              Center(
                child: Container(
                  height: 120, // 48 * 3 = 144, shows 3 items at a time
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 48,
                    diameterRatio: 1.2,
                    perspective: 0.003,
                    squeeze: 1.18,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (value) {
                      setState(() {
                        selectedDay = value + 1;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 15,
                      builder: (context, index) {
                        final isSelected = selectedDay == index + 1;
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
                                    '${index + 1}',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSelected ? 20 : 20,
                                      color: Colors.black,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                // Show "Days" only if selected, aligned to right
                                if (isSelected)
                                  Positioned(
                                    right: 20, // adjust gap from right as you want
                                    child: Text(
                                      'Days',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
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
              child:SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('periodLength', selectedDay);
                    if (widget.fromSettings) {
                      Navigator.pop(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OnboardStep2(periodLength: selectedDay)),
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
              ),),

              // Bottom gap
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}