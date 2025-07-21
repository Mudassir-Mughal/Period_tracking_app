import 'package:calender_app/screens/question3.dart';
import 'package:calender_app/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifier.dart';

class Calender extends StatefulWidget {
  const Calender({super.key});

  @override
  State<Calender> createState() => _CalenderState();
}

class _CalenderState extends State<Calender> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {};
  final Map<DateTime, String?> _notes = {};
  DateTime? lastPeriodStart;
  int cycleLength = 28;
  int periodLength = 5;

  @override
  void initState() {
    super.initState();
    loadUserData();
    modeChangeNotifier.addListener(_onModeChange);
  }

  void _onModeChange() {
    loadUserData();
    setState(() {});
  }

  @override
  void dispose() {
    modeChangeNotifier.removeListener(_onModeChange);
    super.dispose();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPeriodDateStr = prefs.getString('lastPeriodDate');
    cycleLength = prefs.getInt('cycleLength') ?? 28;
    periodLength = prefs.getInt('periodLength') ?? 5;

    _events.clear();
    _notes.clear();
    if (lastPeriodDateStr != null) {
      lastPeriodStart = DateTime.parse(lastPeriodDateStr);
      generateCycleEvents();
      await _loadNotes();
    } else {
      lastPeriodStart = null;
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
      if (note != null && note.isNotEmpty) {
        _notes[DateTime(day.year, day.month, day.day)] = note;
      }
    }
  }

  void _addEvent(DateTime day, String label) {
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
    return _events[DateTime(day.year, day.month, day.day)] ?? <String>[];
  }

  Color? _customCellColor(DateTime day) {
    final events = _getEventsForDay(day);
    if (events.contains("Period")) return const Color(0xFFFFC7DB); // Pink
    if (events.contains("Ovulation")) return const Color(0xFFFFF3C7); // Yellow
    if (events.contains("Fertile")) return const Color(0xFFFFF3C7); // Yellow
    return Colors.white;
  }

  Widget _buildCellSymbols(DateTime day) {
    final events = _getEventsForDay(day);
    final hasNote = _notes.containsKey(DateTime(day.year, day.month, day.day));
    List<Widget> stackChildren = [];
    // Fertile/ovulation symbol at top left
    if (events.contains("Fertile")) {
      stackChildren.add(Positioned(
        top: 2,
        left: 2,
        child: Text("🌱", style: GoogleFonts.poppins(fontSize: 10, height: 1)),
      ));
    }
    if (events.contains("Ovulation")) {
      stackChildren.add(Positioned(
        top: 2,
        left: 2,
        child: Icon(Icons.brightness_1, color: Color(0xFFFF4F8B), size: 10),
      ));
    }
    // Note symbol at top right
    if (hasNote) {
      stackChildren.add(Positioned(
        top: 2,
        right: 2,
        child: Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB35AFF), size: 14),
      ));
    }
    return Stack(children: stackChildren);
  }

  String _eventTypeText(List<String> events) {
    if (events.contains("Period")) return "Period day";
    if (events.contains("Fertile")) return "Fertile day";
    if (events.contains("Ovulation")) return "Ovulation day";
    return "";
  }

  void _gotoSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    await loadUserData();
    setState(() {});
  }

  void _gotoQuestion3() async {
    final prefs = await SharedPreferences.getInstance();
    int period = prefs.getInt('periodLength') ?? 5;
    int cycle = prefs.getInt('cycleLength') ?? 28;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OnboardStep3(
        periodLength: period,
        cycleLength: cycle,
      )),
    );
    await loadUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const mainPink = Color(0xFFFF4F8B);
    final List<String> events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <String>[];

    String cycleDayText = "";
    String annotateText = "";
    Color annotateColor = Colors.transparent;

    if (_selectedDay != null && lastPeriodStart != null) {
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
        ? _notes[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EC),
      body: Column(
        children: [
          // Fixed top section
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12, left: 10, right: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _gotoSettings,
                    child: Icon(Icons.settings, color: mainPink, size: 28),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Calendar",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.notifications, color: mainPink, size: 28),
                    onPressed: () {},
                    splashRadius: 28,
                  ),
                ],
              ),
            ),
          ),
          // Month selector (fixed)
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.chevron_left, color: mainPink, size: 36),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                        });
                      },
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Color(0xFF232323), size: 19),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMM().format(_focusedDay),
                      style: GoogleFonts.poppins(
                        color: Color(0xFF232323),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.chevron_right, color: mainPink, size: 36),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Day names row (fixed)
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 0, top: 0, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (final day in ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Calendar (fixed)
          Container(
            width: 308,
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
              rowHeight: 44,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final color = _customCellColor(day);
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: Color(0xFFD9D9D9), width: 1),
                        ),
                        width: 44,
                        height: 44,
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
                      _buildCellSymbols(day),
                    ],
                  );
                },
                selectedBuilder: (context, day, _) {
                  final color = _customCellColor(day);
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: mainPink, width: 2),
                        ),
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: mainPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      _buildCellSymbols(day),
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
                  fontSize: 15,
                ),
                defaultTextStyle: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                outsideTextStyle: GoogleFonts.poppins(
                  color: Color(0xFFC5C5C5),
                  fontSize: 15,
                ),
                weekendTextStyle: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                todayDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          // Edit period date button (fixed)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 14),
            child: SizedBox(
              width: 240,
              height: 46,
              child: ElevatedButton(
                onPressed: _gotoQuestion3,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainPink.withOpacity(0.23),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Edit period date",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF232323),
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          // Scrollable section for day details
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_selectedDay != null)
                    Container(
                      width: 308,
                      margin: const EdgeInsets.only(top: 0, bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Color(0xFFD9D9D9), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.MMMd().format(_selectedDay!),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.black,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (cycleDayText.isNotEmpty)
                            Text(
                              cycleDayText,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (_eventTypeText(events).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _eventTypeText(events),
                                style: GoogleFonts.poppins(
                                  color: mainPink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (annotateText.isNotEmpty)
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
                                  margin: const EdgeInsets.only(right: 8, top: 2),
                                ),
                                Text(
                                  annotateText,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[800],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          if (selectedNote != null && selectedNote.trim().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 18),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EFFF),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB35AFF).withOpacity(0.07),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB35AFF), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedNote,
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF232323),
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}