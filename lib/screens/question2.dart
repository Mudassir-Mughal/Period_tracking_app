import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'question3.dart';

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
  final Color bgWhite = Colors.white;

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
      backgroundColor: bgWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Progress bar
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(
                      value: 2 / 3,
                      backgroundColor: lightPink.withOpacity(0.2),
                      color: primaryPink,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Question Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightPink.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPink.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'How many days does your cycle usually last?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryPink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        height: 150,
                        child: ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          itemExtent: 40,
                          diameterRatio: 1.3,
                          perspective: 0.003,
                          squeeze: 1.15,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (value) {
                            setState(() {
                              cycleLength = value + 16;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 84, // 16 to 99
                            builder: (context, index) {
                              final isSelected = cycleLength == index + 16;
                              return AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: isSelected ? 26 : 18,
                                  color: isSelected
                                      ? primaryPink
                                      : Colors.grey.shade600,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                child: Text('${index + 16} days'),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Selected: $cycleLength days',
                        style: TextStyle(
                          color: primaryPink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Gradient Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('cycleLength', cycleLength);
                          if (widget.fromSettings) {
                              Navigator.pop(context); // just return to settings page
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                    OnboardStep3(
                                      periodLength: widget.periodLength,
                                      cycleLength: cycleLength,
                                    ),
                              ),
                            );
                          } },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryPink, lightPink],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
