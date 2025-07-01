import 'package:calender_app/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  bool _shouldReload = true;

  DateTime? lastPeriodStart;
  int cycleLength = 28;
  int periodLength = 5;

  bool isPregnancy = false;
  DateTime? pregnancyStartDate;

  @override
  void initState() {
    super.initState();
    _shouldReload = true;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Load pregnancy mode
    isPregnancy = prefs.getBool('pregnancyMode') ?? false;
    final pStart = prefs.getString('pregnancyStartDate');
    pregnancyStartDate = pStart != null ? DateTime.tryParse(pStart) : null;

    // Load period data
    final lastPeriodDateStr = prefs.getString('lastPeriodDate');
    cycleLength = prefs.getInt('cycleLength') ?? 28;
    periodLength = prefs.getInt('periodLength') ?? 5;

    _events.clear();
    if (!isPregnancy && lastPeriodDateStr != null) {
      lastPeriodStart = DateTime.parse(lastPeriodDateStr);
      generateCycleEvents();
      await _loadNotes();
    } else {
      lastPeriodStart = null;
      await _loadNotes(); // Still load notes for pregnancy mode
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
    for (var entry in _events.entries) {
      final day = entry.key;
      String key = DateFormat('yyyy-MM-dd').format(day);
      String? note = prefs.getString('note_$key');
      if (note != null && note.isNotEmpty) {
        _notes[day] = note;
      }
    }
    for (int i = -120; i <= 400; i++) {
      final day = DateTime.now().add(Duration(days: i));
      String key = DateFormat('yyyy-MM-dd').format(day);
      String? note = prefs.getString('note_$key');
      if (note != null && note.isNotEmpty) {
        _notes[DateTime(day.year, day.month, day.day)] = note;
      }
    }
  }

  Future<void> _editNoteDialog(DateTime day, String? existingNote) async {
    final prefs = await SharedPreferences.getInstance();
    final TextEditingController controller = TextEditingController(text: existingNote ?? "");
    bool noteChanged = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your note here',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFFD6BA2))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFD6BA2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              String key = DateFormat('yyyy-MM-dd').format(day);
              if (controller.text.trim().isNotEmpty) {
                await prefs.setString('note_$key', controller.text.trim());
                _notes[DateTime(day.year, day.month, day.day)] = controller.text.trim();
              } else {
                await prefs.remove('note_$key');
                _notes.remove(DateTime(day.year, day.month, day.day));
              }
              noteChanged = true;
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (noteChanged) {
      setState(() {});
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
    if (isPregnancy) return Colors.transparent;
    final events = _getEventsForDay(day);
    if (events.contains("Period")) return const Color(0xFFFFEEF3);
    if (events.contains("Ovulation")) return const Color(0xFFFFF9E6);
    if (events.contains("Fertile")) return const Color(0xFFFFF9E6);
    return Colors.transparent;
  }

  Color _customNumberColor(DateTime day, {required bool selected}) {
    if (isPregnancy) return selected ? const Color(0xFF7C3AED) : const Color(0xFF232323);
    final events = _getEventsForDay(day);
    if (selected) return const Color(0xFF7C3AED);
    if (events.contains("Period")) return const Color(0xFFFF6E9A);
    if (events.contains("Fertile")) return const Color(0xFF4DB96A);
    if (events.contains("Ovulation")) return const Color(0xFFFFB74D);
    return const Color(0xFF232323);
  }

  Widget _buildCellSymbols(DateTime day) {
    final hasNote = _notes.containsKey(DateTime(day.year, day.month, day.day));
    if (isPregnancy && pregnancyStartDate != null) {
      int pregDay = day.difference(pregnancyStartDate!).inDays + 1;
      if (pregDay < 1 || pregDay > 280) {
        // Just show note if present
        if (hasNote) {
          return const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB35AFF), size: 13);
        }
        return const SizedBox.shrink();
      }
      if (pregDay == 280) {
        // Baby icon
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.baby_changing_station, color: Color(0xFFFD6BA2), size: 14),
            if (hasNote)
              const Padding(
                padding: EdgeInsets.only(top: 1.5),
                child: Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB35AFF), size: 13),
              ),
          ],
        );
      }
      // Just the number, plus (optionally) the note symbol below it
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$pregDay",
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFD6BA2),
            ),
          ),
          if (hasNote)
            const Padding(
              padding: EdgeInsets.only(top: 1.5),
              child: Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB35AFF), size: 13),
            ),
        ],
      );
    }
    // Normal period/fertile/ovulation and note icon
    List<Widget> icons = [];
    final events = _getEventsForDay(day);
    if (_notes.containsKey(DateTime(day.year, day.month, day.day))) {
      icons.add(const Padding(
        padding: EdgeInsets.only(right: 1.5),
        child: Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB35AFF), size: 13),
      ));
    }
    if (events.contains("Fertile")) {
      icons.add(const Padding(
        padding: EdgeInsets.only(right: 1.5),
        child: Text("🌱", style: TextStyle(fontSize: 10)),
      ));
    } else if (events.contains("Ovulation")) {
      icons.add(const Padding(
        padding: EdgeInsets.only(right: 1.5),
        child: Text("🟠", style: TextStyle(fontSize: 10)),
      ));
    }
    return icons.isEmpty
        ? const SizedBox.shrink()
        : Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  Widget _eventChip(String label) {
    Color color;
    IconData? icon;
    String textLabel;
    switch (label) {
      case "Period":
        color = const Color(0xFFFF6E9A);
        icon = Icons.water_drop_rounded;
        textLabel = "Period";
        break;
      case "Fertile":
        color = const Color(0xFF4DB96A);
        icon = Icons.spa_rounded;
        textLabel = "Fertile";
        break;
      case "Ovulation":
        color = const Color(0xFFFFB74D);
        icon = Icons.blur_circular;
        textLabel = "Ovulation";
        break;
      default:
        color = const Color(0xFFBDBDBD);
        icon = null;
        textLabel = label;
    }
    return Container(
      margin: const EdgeInsets.only(right: 10, top: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
          ],
          Text(
            textLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteBox(String note, DateTime day) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(15),
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
          const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB35AFF), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                color: Color(0xFF232323),
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _editNoteDialog(day, note);
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEDE6FB),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(left: 8, top: 2),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFFB35AFF), size: 17),
                  SizedBox(width: 4),
                  Text(
                    "Edit",
                    style: TextStyle(
                      color: Color(0xFFB35AFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _cycleDayInfo(DateTime day, List<String> events) {
    if (isPregnancy) {
      // Show pregnancy day or baby born info
      if (pregnancyStartDate == null) return const SizedBox.shrink();
      int pregDay = day.difference(pregnancyStartDate!).inDays + 1;
      if (pregDay < 1) return const SizedBox.shrink();
      if (pregDay > 280) {
        return Container(
          margin: const EdgeInsets.only(top: 10, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF3F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: const [
              Text(
                "Baby born!",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFFD6BA2),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Text("🍼", style: TextStyle(fontSize: 22)),
            ],
          ),
        );
      }
      return Container(
        margin: const EdgeInsets.only(top: 10, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF3F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          "Pregnancy day $pregDay of 280",
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFFD6BA2),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (lastPeriodStart == null) {
      return const SizedBox.shrink();
    }
    String details = "";
    int periodDay = 0;
    if (events.contains("Period")) {
      periodDay = day.difference(lastPeriodStart!).inDays % cycleLength + 1;
      details = "Day $periodDay of the predicted cycle";
    } else if (events.contains("Fertile")) {
      details = "Fertile window";
    } else if (events.contains("Ovulation")) {
      details = "Ovulation day";
    } else {
      details = "No predicted event";
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        details,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF757575),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainPink = Color(0xFFFD6BA2);
    final List<String> events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <String>[];
    final selectedDateKey = _selectedDay != null
        ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
        : null;
    final noteText = selectedDateKey != null ? _notes[selectedDateKey] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Calender",
          style: TextStyle(
            color: mainPink,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: mainPink),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              // ALWAYS force reload after coming back from settings!
              await loadUserData();
              setState(() {});
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
              child: TableCalendar(
                daysOfWeekHeight: 40,
                firstDay: DateTime.now().subtract(const Duration(days: 90)),
                lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selectedDay, focusedDay) async {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = selectedDay;
                  });
                  await _loadNotes();
                  setState(() {});
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Color(0xFF232323),
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: Color(0xFF232323),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: false,
                  selectedDecoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF7C3AED), width: 4.2),
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                  defaultTextStyle: const TextStyle(
                    color: Color(0xFF232323),
                    fontSize: 19,
                  ),
                  outsideTextStyle: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 19,
                  ),
                  weekendTextStyle: const TextStyle(
                    color: Color(0xFF232323),
                    fontSize: 19,
                  ),
                  cellMargin: EdgeInsets.zero,
                  todayDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: const TextStyle(
                    color: Color(0xFF232323),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF232323)),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF232323)),
                  headerMargin: const EdgeInsets.only(bottom: 0),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final color = _customCellColor(day);
                    return Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      margin: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 19,
                                color: _customNumberColor(day, selected: false),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 2,
                            top: 2,
                            child: _buildCellSymbols(day),
                          ),
                        ],
                      ),
                    );
                  },
                  selectedBuilder: (context, day, _) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF7C3AED), width: 2.2),
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      margin: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 19,
                                color: _customNumberColor(day, selected: true),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 2,
                            top: 2,
                            child: _buildCellSymbols(day),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_selectedDay != null)
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(top: 24, left: 15, right: 15, bottom: 18),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: mainPink.withOpacity(0.09),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and event chips
                        Row(
                          children: [
                            Text(
                              DateFormat.MMMMd().format(_selectedDay!),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF232323),
                              ),
                            ),
                            const Spacer(),
                            if (!isPregnancy && events.isNotEmpty)
                              Row(
                                children: events.map((e) => _eventChip(e)).toList(),
                              ),
                          ],
                        ),
                        // Show pregnancy day/baby born or cycle info
                        _cycleDayInfo(_selectedDay!, events),
                        if (noteText != null && noteText.trim().isNotEmpty)
                          _noteBox(noteText, _selectedDay!),
                        if (noteText == null || noteText.trim().isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            child: Text(
                              "No notes for this day.",
                              style: TextStyle(
                                fontSize: 15.5,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}