import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'bottomnaviagtor.dart';
import 'home.dart';

class OnboardStep3 extends StatefulWidget {
  final int periodLength;
  final int cycleLength;

  const OnboardStep3({
    super.key,
    required this.periodLength,
    required this.cycleLength,
  });

  @override
  State<OnboardStep3> createState() => _OnboardStep3State();
}

class _OnboardStep3State extends State<OnboardStep3> {
  DateTime selectedDate = DateTime.now();

  final Color primaryPink = const Color(0xFFFF4F8B);
  final Color lightPink = const Color(0xFFFF80AB);
  final Color bgLight = const Color(0xFFFFE4EC);

  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _yearController;

  late List<int> years;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    years = List.generate(3, (index) => now.year - 2 + index);

    _monthController = FixedExtentScrollController(initialItem: selectedDate.month - 1);
    _dayController = FixedExtentScrollController(initialItem: selectedDate.day - 1);
    _yearController = FixedExtentScrollController(initialItem: years.indexOf(selectedDate.year));
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('periodLength', widget.periodLength);
    await prefs.setInt('cycleLength', widget.cycleLength);
    await prefs.setString('lastPeriodDate', selectedDate.toIso8601String());

    // Navigate to home screen
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required Widget Function(int, bool) itemBuilder,
    double width = 80,
  }) {
    return Container(
      width: width,
      height: 120,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        diameterRatio: 1.2,
        squeeze: 1.18,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            DateTime now = DateTime.now();
            int minYear = now.year - 2;
            int maxYear = now.year;
            int year = selectedDate.year;
            int month = selectedDate.month;
            int day = selectedDate.day;

            if (controller == _yearController) {
              year = years[index];
              // Clamp month and day for new year if needed
              if (year == now.year && month > now.month) month = now.month;
              int daysInSelectedMonth = daysInMonth(year, month);
              if (year == now.year && month == now.month && day > now.day) day = now.day;
              if (day > daysInSelectedMonth) day = daysInSelectedMonth;
            } else if (controller == _monthController) {
              month = (year == now.year && index + 1 > now.month) ? now.month : index + 1;
              int daysInSelectedMonth = daysInMonth(year, month);
              if (year == now.year && month == now.month && day > now.day) day = now.day;
              if (day > daysInSelectedMonth) day = daysInSelectedMonth;
            } else if (controller == _dayController) {
              int maxDay = (year == now.year && month == now.month) ? now.day : daysInMonth(year, month);
              day = (index + 1 > maxDay) ? maxDay : index + 1;
            }

            // Make the new date and clamp to today if needed
            DateTime newDate = DateTime(year, month, day);
            if (newDate.isAfter(now)) {
              newDate = now;
            }
            selectedDate = newDate;

            // Sync pickers with the new date
            if (_yearController.selectedItem != years.indexOf(selectedDate.year)) {
              _yearController.jumpToItem(years.indexOf(selectedDate.year));
            }
            if (_monthController.selectedItem != selectedDate.month - 1) {
              _monthController.jumpToItem(selectedDate.month - 1);
            }
            if (_dayController.selectedItem != selectedDate.day - 1) {
              _dayController.jumpToItem(selectedDate.day - 1);
            }
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, idx) {
            final isSelected = idx == selectedIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 48,
                decoration: isSelected
                    ? BoxDecoration(
                  color: primaryPink.withOpacity(0.32),
                  borderRadius: BorderRadius.circular(14),
                )
                    : null,
                alignment: Alignment.center,
                child: itemBuilder(idx, isSelected),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int minYear = now.year - 2;
    int maxYear = now.year;
    int selectedYear = selectedDate.year;
    int selectedMonth = selectedDate.month;
    int selectedDay = selectedDate.day;

    // Years: minYear to maxYear
    final List<int> shownYears = years;

    // Months: If current year, only up to this month
    int maxMonth = (selectedYear == now.year) ? now.month : 12;
    final List<String> shownMonths = List.generate(
      maxMonth,
          (i) => DateFormat('MMM').format(DateTime(0, i + 1)),
    );
    int monthIdx = (selectedMonth - 1).clamp(0, shownMonths.length - 1);

    // Days: If current year and month, only up to today
    int maxDay = (selectedYear == now.year && selectedMonth == now.month)
        ? now.day
        : daysInMonth(selectedYear, selectedMonth);
    int dayIdx = (selectedDay - 1).clamp(0, maxDay - 1);

    return Scaffold(
      backgroundColor: bgLight,
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
                            width: 180,
                            child: LinearProgressIndicator(
                              value: 3 / 3,
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
                  "What’s the start date of your\nLast period?",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: primaryPink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 90),

              // Pickers Row
              Center(
                child: SizedBox(
                  width: 280,
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Month Picker
                      _buildPicker(
                        controller: _monthController,
                        itemCount: shownMonths.length,
                        selectedIndex: monthIdx,
                        width: 80,
                        itemBuilder: (idx, isSelected) => Text(
                          shownMonths[idx],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 26,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      // Day Picker
                      _buildPicker(
                        controller: _dayController,
                        itemCount: maxDay,
                        selectedIndex: dayIdx,
                        width: 70,
                        itemBuilder: (idx, isSelected) => Text(
                          (idx + 1).toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 26,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      // Year Picker
                      _buildPicker(
                        controller: _yearController,
                        itemCount: shownYears.length,
                        selectedIndex: shownYears.indexOf(selectedYear),
                        width: 90,
                        itemBuilder: (idx, isSelected) => Text(
                          shownYears[idx].toString(),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 26,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
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
                    onPressed: saveUserData,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: primaryPink,
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
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