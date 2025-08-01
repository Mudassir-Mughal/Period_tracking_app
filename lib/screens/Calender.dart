// [Your imports remain unchanged]
import 'dart:convert';

import 'package:calender_app/screens/addnote.dart';
import 'package:calender_app/screens/question3.dart';
import 'package:calender_app/screens/reminder.dart';
import 'package:calender_app/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottomnaviagtor.dart';
import 'notifier.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class Calender extends StatefulWidget {
  const Calender({super.key});

  @override
  State<Calender> createState() => _CalenderState();
}

class _CalenderState extends State<Calender> with WidgetsBindingObserver {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {};
  final Map<DateTime, Map<String, dynamic>> _notes = {};
  DateTime? lastPeriodStart;
  int cycleLength = 28;
  int periodLength = 5;

  // Pregnancy mode variables
  bool isPregnancyMode = false;
  DateTime? pregnancyStartDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadUserData();
    modeChangeNotifier.addListener(_onModeChange);
  }

  void _onModeChange() async {
    await loadUserData();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadUserData();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    modeChangeNotifier.removeListener(_onModeChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPeriodDateStr = prefs.getString('lastPeriodDate');
    cycleLength = prefs.getInt('cycleLength') ?? 28;
    periodLength = prefs.getInt('periodLength') ?? 5;

    // Consistent pregnancy keys with HomeScreen
    final pMode = prefs.getBool('pregnancyMode') ?? false;
    final pStart = prefs.getString('pregnancyStartDate');
    isPregnancyMode = pMode && pStart != null;
    pregnancyStartDate = pStart != null ? DateTime.tryParse(pStart) : null;

    _events.clear();
    _notes.clear();
    if (!isPregnancyMode && lastPeriodDateStr != null) {
      lastPeriodStart = DateTime.parse(lastPeriodDateStr);
      generateCycleEvents();
      await _loadNotes();
    } else {
      lastPeriodStart = null;
      await _loadNotes();
    }
    setState(() {});
  }

  void generateCycleEvents() {
    if (lastPeriodStart == null) return;
    DateTime cycleStart = lastPeriodStart!;
    for (int i = 0; i < 12; i++) {
      for (int j = 0; j < periodLength; j++) {
        final periodDay = cycleStart.add(Duration(days: j));
        _addEvent(periodDay, "Period");
      }
      DateTime fertileStart = cycleStart.add(Duration(days: periodLength));
      for (int k = 0; k < 6; k++) {
        final fertileDay = fertileStart.add(Duration(days: k));
        if (k == 5) {
          _addEvent(fertileDay, "Ovulation");
        } else {
          _addEvent(fertileDay, "Fertile");
        }
      }
      cycleStart = cycleStart.add(Duration(days: cycleLength));
    }
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    _notes.clear();

    for (int i = -120; i <= 400; i++) {
      final day = DateTime.now().add(Duration(days: i));
      String key = DateFormat('yyyy-MM-dd').format(day);

      String? note = prefs.getString('note_$key');
      String? mood = prefs.getString('mood_$key');
      int? flow = prefs.getInt('flow_$key');
      String? condom = prefs.getString('condom_$key');
      String? orgasm = prefs.getString('orgasm_$key');
      int? intercourse = prefs.getInt('intercourseTimes_$key');
      double? weight = prefs.getDouble('weight_$key');
      double? temperature = prefs.getDouble('temperature_$key');

      // Water details
      int? waterGlasses = prefs.getInt('waterGlasses_$key');
      int? glassMl = prefs.getInt('glassMl_$key');
      int? targetMl = prefs.getInt('targetMl_$key');

      // Symptoms stars
      String? symptomStarsStr = prefs.getString('symptomStars_$key');
      List<int> symptomStars = [];
      if (symptomStarsStr != null) {
        try {
          symptomStars = List<int>.from(jsonDecode(symptomStarsStr));
        } catch (_) {}
      }

      // Prepare left and right column details
      List<Map<String, dynamic>> left = [];
      List<Map<String, dynamic>> right = [];

      // Left column (notes, intercourse, mood, etc)
      if (note != null && note.isNotEmpty) {
        left.add({"type": "note", "text": note});
      }
      if (mood != null && mood.isNotEmpty) {
        left.add({"type": "mood", "text": mood});
      }
      if (intercourse != null && intercourse > 0) {
        left.add({"type": "intercourse", "text": "$intercourse times"});
      }
      if (condom != null && condom.isNotEmpty) {
        left.add({"type": "condom", "text": condom});
      }
      if (orgasm != null && orgasm.isNotEmpty) {
        left.add({"type": "orgasm", "text": 'Female Orgasm: $orgasm'});
      }

      // Right column (water, temperature, flow, symptoms)
      if (waterGlasses != null && glassMl != null && targetMl != null && waterGlasses > 0) {
        right.add({
          "type": "water",
          "icon": Icons.local_drink,
          "text": "${waterGlasses * glassMl} ml"
        });
      }
      if (temperature != null) {
        right.add({
          "type": "temperature",
          "icon": Icons.device_thermostat,
          "text": "${temperature.toStringAsFixed(1)} °C"
        });
      }

      if (weight != null) {
        right.add({
          "type": "weight",
          "icon": Icons.monitor_weight,
          "text": "${weight.toStringAsFixed(1)} kg"
        });
      }
      if (flow != null && flow > 0) {
        right.add({
          "type": "flow",
          "icon": Icons.water_drop,
          "stars": flow
        });
      }
      // Symptoms
      if (symptomStars.isNotEmpty && symptomStars.any((s) => s > 0)) {
        final symptomNames = ['backpain', 'Anxiety', 'Headache', 'Cravings'];

        // Update these paths to match your actual assets!
        final symptomAssetIcons = [
          "assets/backpain.png",
          "assets/Anxiety.png",
          "assets/Headache.png",
          "assets/cravings.png",
        ];
        for (int j = 0; j < symptomStars.length; j++) {
          if (symptomStars[j] > 0) {
            right.add({
              "type": "symptom",
              "icon": symptomAssetIcons[j], // <-- use asset path instead of IconData
              "label": symptomNames[j],
              "stars": symptomStars[j]
            });
          }
        }
      }

      if (left.isNotEmpty || right.isNotEmpty) {
        _notes[DateTime(day.year, day.month, day.day)] = {
          "left": left,
          "right": right,
        };
      }
    }
    setState(() {});
  }

  void _addEvent(DateTime day, String label) {
    if (isPregnancyMode) return; // Don't add events in pregnancy mode
    final date = DateTime(day.year, day.month, day.day);
    if (_events.containsKey(date)) {
      if (!_events[date]!.contains(label)) {
        _events[date]!.add(label);
      }
    } else {
      _events[date] = [label];
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    if (isPregnancyMode) return <String>[]; // No cycle events in pregnancy mode
    return _events[DateTime(day.year, day.month, day.day)] ?? <String>[];
  }

  Color? _customCellColor(DateTime day) {
    if (isPregnancyMode) return Colors.white; // No coloring in pregnancy mode
    final events = _getEventsForDay(day);
    if (events.contains("Period")) return const Color(0xFFFFC7DB); // Pink
    if (events.contains("Ovulation")) return const Color(0xFFFFF3C7); // Yellow
    if (events.contains("Fertile")) return const Color(0xFFFFF3C7); // Yellow
    return Colors.white;
  }

  /// Always show note symbol if a note exists, in pregnancy mode place on left
  Widget _buildCellSymbols(DateTime day) {
    final events = _getEventsForDay(day);
    final hasNote = _notes.containsKey(DateTime(day.year, day.month, day.day));
    List<Widget> stackChildren = [];

    // Note symbol always shown, position left if pregnancy mode, right otherwise
    if (hasNote) {
      stackChildren.add(
        Positioned(
          top: 2,
          left: isPregnancyMode ? 2 : null,
          right: isPregnancyMode ? null : 2,
          child: Icon(
            Icons.sticky_note_2_rounded,
            color: Color(0xFFB35AFF),
            size: 14,
          ),
        ),
      );
    }

    // Only show cycle symbols if not pregnancy mode
    if (!isPregnancyMode) {
      if (events.contains("Fertile")) {
        stackChildren.add(
          Positioned(
            top: 2,
            left: 2,
            child: Text(
              "🌱",
              style: GoogleFonts.poppins(fontSize: 10, height: 1),
            ),
          ),
        );
      }
      if (events.contains("Ovulation")) {
        stackChildren.add(
          Positioned(
            top: 2,
            left: 2,
            child: Icon(Icons.brightness_1, color: Color(0xFFFF4F8B), size: 10),
          ),
        );
      }
    }

    return Stack(children: stackChildren);
  }

  String _eventTypeText(List<String> events) {
    if (isPregnancyMode) return "";
    if (events.contains("Period")) return "Period day";
    if (events.contains("Fertile")) return "Fertile day";
    if (events.contains("Ovulation")) return "Ovulation day";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    const mainPink = Color(0xFFFD6BA2);
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = 16.0; // Consistent margin for all devices
    final List<String> events = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : <String>[];

    String cycleDayText = "";
    String annotateText = "";
    Color annotateColor = Colors.transparent;

    if (!isPregnancyMode && _selectedDay != null && lastPeriodStart != null) {
      final daysSince = _selectedDay!.difference(lastPeriodStart!).inDays;
      final mod = daysSince % cycleLength;
      int cycleDay = (mod < 0 ? mod + cycleLength : mod) + 1;
      cycleDayText = "Cycle Day $cycleDay";

      if (events.contains("Fertile") || events.contains("Ovulation")) {
        annotateText = "High - chance of pregnant";
        annotateColor = mainPink;
      }
    }

    final selectedNote = _selectedDay != null
        ? _notes[DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    )]
        : null;

    // Pregnancy day for today (below calendar)
    int? todayPregnancyDay;
    if (isPregnancyMode && pregnancyStartDate != null) {
      todayPregnancyDay = DateTime.now().difference(pregnancyStartDate!).inDays + 1;
      if (todayPregnancyDay! < 1 || todayPregnancyDay > 280) {
        todayPregnancyDay = null;
      }
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(theme.backgroundImage, fit: BoxFit.cover),
          ),
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                    bottom: 0,
                    left: 10,
                    right: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => MainScreen(initialTab: 0)),
                          );
                        },
                        splashRadius: 24,
                      ),
                      Text(
                        "Calendar",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.notifications,
                          color: theme.accentColor,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RemindersScreen(),
                            ),
                          );
                        },
                        splashRadius: 28,
                      ),
                    ],
                  ),
                ),
              ),

              // Month selector AND weekday row in same (padded) container
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    // Month selector row with left/right chevrons aligned with calendar columns
                    Row(
                      children: [
                        // Left icon aligned to first grid column
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                color: mainPink,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month - 1,
                                    1,
                                  );
                                });
                              },
                            ),
                          ),
                        ),
                        // Month name with icon, spans 5 columns
                        Expanded(
                          flex: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF232323),
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.yMMMM().format(_focusedDay),
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF232323),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right icon aligned to last grid column
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(
                                Icons.chevron_right,
                                color: mainPink,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month + 1,
                                    1,
                                  );
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Day names row, perfectly aligned
                    Row(
                      children: [
                        for (final day in [
                          "Sun",
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                        ])
                          Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Calendar (responsive, padded)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: double.infinity, // fills the available width inside padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Color(0xFFD9D9D9), width: 1.2),
                  ),
                  child: TableCalendar(
                    daysOfWeekVisible: false,
                    daysOfWeekHeight: 0,
                    firstDay: DateTime.now().subtract(const Duration(days: 90)),
                    lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    onDaySelected: (selectedDay, focusedDay) async {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = selectedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    headerVisible: false,
                    rowHeight: (deviceWidth - 2 * horizontalPadding) / 7, // squares and always fits screen with padding
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, _) {
                        final color = _customCellColor(day);
                        final hasNote = _notes.containsKey(DateTime(day.year, day.month, day.day));

                        // --- Pregnancy day number as you want (pink bg, white, font size 10, bold) ---
                        Widget pregnancyDayNumber = SizedBox.shrink();
                        int? pregDay;
                        if (isPregnancyMode && pregnancyStartDate != null) {
                          pregDay = day.difference(pregnancyStartDate!).inDays ;
                          if (pregDay < 1 || pregDay > 280) pregDay = null;
                        }
                        if (pregDay != null) {
                          pregnancyDayNumber = Positioned(
                            top: 3,
                            right: 3,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Color(0xFFFD6BA2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$pregDay',
                                style: GoogleFonts.poppins(
                                  fontSize: 6,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        // --- END ---

                        // Note icon always, left in pregnancy mode
                        Widget noteIcon = hasNote
                            ? Positioned(
                          top: 2,
                          left: isPregnancyMode ? 2 : null,
                          right: isPregnancyMode ? null : 2,
                          child: Icon(
                            Icons.sticky_note_2_rounded,
                            color: Color(0xFFB35AFF),
                            size: 14,
                          ),
                        )
                            : SizedBox.shrink();

                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(
                                  color: Color(0xFFD9D9D9),
                                  width: 1,
                                ),
                              ),
                              width: (deviceWidth - 2 * horizontalPadding) / 7,
                              height: (deviceWidth - 2 * horizontalPadding) / 7,
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            // Always show note icon if note exists
                            noteIcon,
                            // Pregnancy day number if in pregnancy mode and within 1-280
                            if (pregDay != null) pregnancyDayNumber,
                            // Cycle symbols if not isPregnancyMode
                            if (!isPregnancyMode) _buildCellSymbols(day),
                          ],
                        );
                      },
                      selectedBuilder: (context, day, _) {
                        final color = _customCellColor(day);
                        final hasNote = _notes.containsKey(DateTime(day.year, day.month, day.day));

                        // --- Pregnancy day number as you want (pink bg, white, font size 10, bold) ---
                        Widget pregnancyDayNumber = SizedBox.shrink();
                        int? pregDay;
                        if (isPregnancyMode && pregnancyStartDate != null) {
                          pregDay = day.difference(pregnancyStartDate!).inDays ;
                          if (pregDay < 1 || pregDay > 280) pregDay = null;
                        }
                        if (pregDay != null) {
                          pregnancyDayNumber = Positioned(
                            top: 3,
                            right: 3,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Color(0xFFFD6BA2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$pregDay',
                                style: GoogleFonts.poppins(
                                  fontSize: 6,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        // --- END ---

                        // Note icon always, left in pregnancy mode
                        Widget noteIcon = hasNote
                            ? Positioned(
                          top: 2,
                          left: isPregnancyMode ? 2 : null,
                          right: isPregnancyMode ? null : 2,
                          child: Icon(
                            Icons.sticky_note_2_rounded,
                            color: Color(0xFFB35AFF),
                            size: 14,
                          ),
                        )
                            : SizedBox.shrink();

                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(color: mainPink, width: 2),
                              ),
                              width: (deviceWidth - 2 * horizontalPadding) / 7,
                              height: (deviceWidth - 2 * horizontalPadding) / 7,
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: mainPink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            noteIcon,
                            if (pregDay != null) pregnancyDayNumber,
                            if (!isPregnancyMode) _buildCellSymbols(day),
                          ],
                        );
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      isTodayHighlighted: false,
                      tablePadding: EdgeInsets.zero,
                      cellMargin: EdgeInsets.zero,
                      cellPadding: EdgeInsets.zero,
                      selectedDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      selectedTextStyle: GoogleFonts.poppins(
                        color: mainPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      defaultTextStyle: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      outsideTextStyle: GoogleFonts.poppins(
                        color: Color(0xFFC5C5C5),
                        fontSize: 14,
                      ),
                      weekendTextStyle: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      todayDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Edit period date button (fixed)
              if (!isPregnancyMode)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OnboardStep3(
                            periodLength: periodLength,
                            cycleLength: cycleLength,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFD6BA2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Edit Period',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              if (!isPregnancyMode) SizedBox(height: 12),
              // Scrollable section for day details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_selectedDay != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 0, bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Color(0xFFD9D9D9),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Row for date and edit button only
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat.MMMd().format(_selectedDay!),
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.black,
                                          letterSpacing: 0.2,
                                          height: 2
                                      ),
                                    ),

                                    if (selectedNote != null)
                                      IconButton(
                                        icon: Icon(Icons.edit, color: mainPink, size: 20),
                                        onPressed: () {
                                          String? noteText;
                                          if (selectedNote != null && selectedNote['left'] != null) {
                                            for (final item in selectedNote['left']) {
                                              if (item['type'] == 'note') {
                                                noteText = item['text'];
                                                break;
                                              }
                                            }
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AddNoteScreen(
                                                date: _selectedDay!,
                                                existingNote: noteText,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                // Pregnancy selected day info
                                if (isPregnancyMode && pregnancyStartDate != null) ...[
                                  Builder(builder: (context) {
                                    int selPregDay = _selectedDay!.difference(pregnancyStartDate!).inDays ;
                                    if (selPregDay >= 1 && selPregDay <= 280) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 0, bottom: 4),
                                        child: Text(
                                          "Pregnancy Day $selPregDay",
                                          style: GoogleFonts.poppins(
                                            color: Colors.pink,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  }),
                                ],
                                // Cycle day below, as a separate widget
                                if (!isPregnancyMode && cycleDayText.isNotEmpty)
                                  Text(
                                    cycleDayText,
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height:1,
                                    ),
                                  ),
                                if (!isPregnancyMode && _eventTypeText(events).isNotEmpty)
                                  Text(
                                    _eventTypeText(events),
                                    style: GoogleFonts.poppins(
                                      color: mainPink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.7,
                                    ),
                                  ),
                                if (!isPregnancyMode && annotateText.isNotEmpty)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: annotateColor,
                                          shape: BoxShape.circle,
                                        ),
                                        margin: const EdgeInsets.only(right: 4),
                                      ),
                                      Text(
                                        annotateText,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                // Two column note display
                                if (selectedNote != null)
                                  Builder(
                                      builder: (context) {
                                        final noteData = selectedNote;
                                        final left = noteData?['left'] ?? [];
                                        final right = noteData?['right'] ?? [];
                                        if (left.isEmpty && right.isEmpty) {
                                          return SizedBox.shrink();
                                        }
                                        if (left.isNotEmpty && right.isNotEmpty) {
                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Left Side: Mood, Note, Intercourse, etc
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: left.map<Widget>((item) {
                                                    Color? dotColor;
                                                    if (item['type'] == 'note') dotColor = Colors.blue;
                                                    if (item['type'] == 'intercourse' || item['type'] == 'condom' || item['type'] == 'orgasm') dotColor = Colors.pink;
                                                    if (dotColor != null) {
                                                      return Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration: BoxDecoration(
                                                              color: dotColor,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            margin: const EdgeInsets.only(right: 4, top:4),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              item['text'],
                                                              style: GoogleFonts.poppins(
                                                                color: Colors.black,
                                                                fontSize: 11,
                                                                height: 1.6,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(left: 14),
                                                        child: Text(
                                                          item['text'],
                                                          style: GoogleFonts.poppins(
                                                            color: Colors.black,
                                                            fontSize: 12,
                                                            height: 1.7,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }).toList(),
                                                ),
                                              ),
                                              // Vertical divider
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 4,),
                                                width: 2,
                                                height: 120,
                                                color: Colors.grey.shade200,
                                              ),
                                              // Right Side: Water, Temp, Flow, Symptoms
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: right.map<Widget>((item) {
                                                    if (item['type'] == 'water' || item['type'] == 'temperature' || item['type'] == 'weight') {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 3),
                                                        child: Row(
                                                          children: [
                                                            Icon(item['icon'], color: Colors.grey[800], size: 15),
                                                            const SizedBox(width: 5),
                                                            Text(
                                                              item['text'],
                                                              style: GoogleFonts.poppins(
                                                                fontWeight: FontWeight.w400,
                                                                fontSize: 12,
                                                                color: Colors.black,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                    if (item['type'] == 'flow') {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 4),
                                                        child: Row(
                                                          children: [
                                                            Icon(item['icon'], size: 15, color: Colors.pink.shade300),
                                                            const SizedBox(width: 7),
                                                            Row(
                                                              children: List.generate(
                                                                item['stars'],
                                                                    (i) => const Icon(Icons.star, color: Colors.orange, size: 12),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                    // SYMPTOM: use Image.asset for asset icons
                                                    if (item['type'] == 'symptom') {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 4),
                                                        child: Row(
                                                          children: [
                                                            Image.asset(
                                                              item['icon'],
                                                              width: 18,
                                                              height: 18,
                                                              fit: BoxFit.contain,
                                                            ),
                                                            const SizedBox(width: 7),
                                                            Row(
                                                              children: List.generate(
                                                                item['stars'],
                                                                    (i) => const Icon(Icons.star, color: Colors.orange, size: 12),
                                                              ),
                                                            ),
                                                        ],),
                                                      );
                                                    }
                                                    return Text(
                                                      item['text'] ?? '',
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          );
                                        } else if (left.isNotEmpty) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: left.map<Widget>((item) {
                                              Color? dotColor;
                                              if (item['type'] == 'note') dotColor = Colors.blue;
                                              if (item['type'] == 'intercourse' || item['type'] == 'condom' || item['type'] == 'orgasm') dotColor = Colors.pink;
                                              if (dotColor != null) {
                                                return Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: dotColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      margin: const EdgeInsets.only(right: 4, top: 3),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        item['text'],
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 12,
                                                          height: 1.25,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              } else {
                                                return Padding(
                                                  padding: const EdgeInsets.only(left: 14),
                                                  child: Text(
                                                    item['text'],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 13,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }).toList(),
                                          );
                                        } else if (right.isNotEmpty) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: right.map<Widget>((item) {
                                              if (item['type'] == 'water' || item['type'] == 'temperature' || item['type'] == 'weight') {
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 3),
                                                  child: Row(
                                                    children: [
                                                      Icon(item['icon'], color: Colors.grey[800], size: 15),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        item['text'],
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w400,
                                                          fontSize: 12,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              if (item['type'] == 'flow') {
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(item['icon'], size: 15, color: Colors.pink.shade300),
                                                      const SizedBox(width: 7),
                                                      Row(
                                                        children: List.generate(
                                                          item['stars'],
                                                              (i) => const Icon(Icons.star, color: Colors.orange, size: 12),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              // SYMPTOM: use Image.asset for asset icons
                                              if (item['type'] == 'symptom') {
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Row(
                                                    children: [
                                                      Image.asset(
                                                        item['icon'],
                                                        width: 20,
                                                        height: 20,
                                                        fit: BoxFit.contain,
                                                      ),
                                                      const SizedBox(width: 7),
                                                      Row(
                                                        children: List.generate(
                                                          item['stars'],
                                                              (i) => const Icon(Icons.star, color: Colors.orange, size: 12),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              return Text(
                                                item['text'] ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              );

                                            }).toList(),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      }
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}