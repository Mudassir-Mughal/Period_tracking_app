import 'package:calender_app/screens/reminder.dart';
import 'package:calender_app/screens/settings.dart';
import 'package:calender_app/screens/calender.dart';
import 'package:calender_app/screens/pregnancysetupscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifier.dart';
import 'package:google_fonts/google_fonts.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Pregnancy mode variables
  bool isPregnancy = false;
  DateTime? pregnancyStartDate;
  int pregnancyOption = 0;

  // Period tracker variables
  DateTime? lastPeriodStart;
  int periodLength = 5;
  int cycleLength = 28;

  DateTime? nextPeriodDate;
  DateTime? nextFertileWindow;
  DateTime? nextOvulation;
  int daysLeft = 0;
  int currentCycleDay = 0;
  bool isOnPeriod = false;

  DateTime? cycleStart;
  DateTime? cycleEnd;
  DateTime? fertileStart;
  DateTime? fertileEnd;
  DateTime? ovulationDay;
  DateTime? periodEnd;

  bool _isLoaded = false;
  int? selectedDayIdx;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
    modeChangeNotifier.addListener(_onModeChange);
  }

  void _onModeChange() {
    _loadAllUserData();
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
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Always load these!
    periodLength = prefs.getInt('periodLength') ?? 5;
    cycleLength = prefs.getInt('cycleLength') ?? 28;

    // Pregnancy mode
    final pMode = prefs.getBool('pregnancyMode') ?? false;
    final pStart = prefs.getString('pregnancyStartDate');
    final pOption = prefs.getInt('pregnancyDisplayOption') ?? 0;

    isPregnancy = pMode && pStart != null;
    if (pStart != null) pregnancyStartDate = DateTime.parse(pStart);
    pregnancyOption = pOption;

    if (!isPregnancy) {
      final lastDate = prefs.getString('lastPeriodDate');
      if (lastDate != null) {
        lastPeriodStart = DateTime.tryParse(lastDate);
        _calculatePhases();
      }
    }

    setState(() { _isLoaded = true; });
  }

  void _calculatePhases() {
    if (lastPeriodStart == null) return;
    final now = DateTime.now();

    cycleStart = lastPeriodStart!;
    while (cycleStart!.isBefore(now)) {
      cycleStart = cycleStart!.add(Duration(days: cycleLength));
    }
    cycleStart = cycleStart!.subtract(Duration(days: cycleLength));
    cycleEnd = cycleStart!.add(Duration(days: cycleLength - 1));
    periodEnd = cycleStart!.add(Duration(days: periodLength - 1));
    fertileStart = periodEnd!.add(const Duration(days: 1));
    fertileEnd = fertileStart!.add(const Duration(days: 5));
    ovulationDay = fertileStart!.add(const Duration(days: 4));

    currentCycleDay = now.difference(cycleStart!).inDays + 1;
    isOnPeriod = currentCycleDay >= 1 && currentCycleDay <= periodLength;
    nextPeriodDate = cycleEnd!.add(const Duration(days: 1));
    daysLeft = nextPeriodDate!.difference(now).inDays;
    nextFertileWindow = fertileStart;
    nextOvulation = ovulationDay;
  }

  void goToCalendar({DateTime? focusDay}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Calender(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isPregnancy && pregnancyStartDate != null) {
      return pregnancyHomeWidget(
        context,
        pregnancyStartDate!,
        pregnancyOption,
            () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PregnancySetupScreen()),
          );
          await _loadAllUserData();
          setState(() {});
        },
      );
    }

    // Check for null values
    if (lastPeriodStart == null ||
        cycleStart == null ||
        cycleEnd == null ||
        fertileStart == null ||
        fertileEnd == null ||
        ovulationDay == null ||
        periodEnd == null) {
      return Scaffold(
        backgroundColor: Color(0xFFFFE6EE),
        body: Center(
          child: Text(
            "No period data found. Please set your period info in settings.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFFFE6EE),
      body: SafeArea(
        child: SingleChildScrollView(  // Added SingleChildScrollView
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                        icon:Icon(Icons.settings, color: Color(0xFFFD6BA2), size: 28,),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                          await _loadAllUserData();
                        },),
                        Text(
                          'Period Tracker',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications, color: Color(0xFFFD6BA2) , size: 28,),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RemindersScreen()),
                        );
                        await _loadAllUserData();
                      },
                    ),
                  ],
                ),
              ),

              // Today's Status Circle with proper shape
              // Replace the existing circle container with this code
              Stack(
                alignment: Alignment.center,
                children: [
                  // Hexagon shape image
                  Image.asset(
                    'assets/vector15.png',  // Your hexagon image path
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),

                  // Pink accent line (bottom left curve)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: CustomPaint(
                      size: Size(140, 140),

                    ),
                  ),

                  // Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Today',
                        style: GoogleFonts.poppins(
                          color: Color(0xFFFD6BA2),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0),
                      Text(
                        isOnPeriod ? 'Period Day' : 'Ovulation Day',
                        style: GoogleFonts.poppins(
                          color: Color(0xFFFD6BA2),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        nextPeriodDate != null
                            ? '${DateFormat('MMM d').format(nextPeriodDate!)} - Next Period'
                            : 'No data',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.normal
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Edit Period Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 60),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => goToCalendar(),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Cycle Phase Card with horizontal scroll
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cycle phase',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // Today's actual phase
                      _buildPhaseBox(
                        'Today',
                        isOnPeriod ? 'Period Day' :
                        (DateTime.now().isAtSameMomentAs(ovulationDay!) ? 'Ovulation' :
                        (DateTime.now().isAfter(fertileStart!) && DateTime.now().isBefore(fertileEnd!) ? 'Fertile Window' : 'Regular Day')),
                        isOnPeriod ? Icons.water_drop :
                        (DateTime.now().isAtSameMomentAs(ovulationDay!) ? Icons.brightness_1 :
                        (DateTime.now().isAfter(fertileStart!) && DateTime.now().isBefore(fertileEnd!) ? Icons.favorite : Icons.circle_outlined)),
                        isOnPeriod ? Color(0xFFFD6BA2) :
                        (DateTime.now().isAtSameMomentAs(ovulationDay!) ? Colors.orange :
                        (DateTime.now().isAfter(fertileStart!) && DateTime.now().isBefore(fertileEnd!) ? Color(0xFFFD6BA2) : Colors.grey)),
                      ),
                      SizedBox(width: 15), // Added more space between boxes
                      // Fertile Window
                      _buildPhaseBox(
                        DateFormat('MMM d').format(fertileStart!),
                        'Fertility Window',
                        Icons.favorite,
                        Color(0xFFFD6BA2),
                      ),
                      SizedBox(width: 15), // Added more space between boxes
                      // Next Period
                      _buildPhaseBox(
                        DateFormat('MMM d').format(nextPeriodDate!),
                        'Next Period',
                        Icons.calendar_today,
                        Color(0xFFFD6BA2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

              SizedBox(height: 20),

              // Cycle Day Info
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jul 29 - Cycle Day ${currentCycleDay}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'LOW CHANCE of Pregnancy',
                      style: GoogleFonts.poppins(
                        color: Color(0xFFFD6BA2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 15),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFD6BA2),
                                Colors.orange,
                                Colors.yellow,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: -20,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${currentCycleDay}D',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),  // Added bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseBox(String date, String title, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25, // Reduced width to prevent overflow
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Icon(icon, color: color, size: 22),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // PREGNANCY HOME WIDGET (no cat image, compact and clean)
  Widget pregnancyHomeWidget(BuildContext context, DateTime startDate, int displayOption, VoidCallback onOptionTap) {
    const mainPink = Color(0xFFFD6BA2);
    final now = DateTime.now();
    final dueDate = startDate.add(const Duration(days: 280));
    final daysSince = now.difference(startDate).inDays;
    final daysLeft = dueDate.difference(now).inDays.clamp(0, 280);
    final weeks = daysSince ~/ 7;
    final days = daysSince % 7;

    String trimester;
    if (weeks < 13) {
      trimester = "1st Trimester";
    } else if (weeks < 27) {
      trimester = "2nd Trimester";
    } else {
      trimester = "3rd Trimester";
    }

    double t1Progress = (weeks < 13) ? (weeks + days / 7) / 13 : 1;
    double t2Progress = (weeks >= 13 && weeks < 27)
        ? ((weeks - 13) + days / 7) / 14
        : (weeks >= 27 ? 1 : 0);
    double t3Progress = (weeks >= 27)
        ? ((weeks - 27) + days / 7) / 13
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Home",
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
              await _loadAllUserData();
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Text(
                  displayOption == 0
                      ? "${weeks}W${days}D"
                      : "$daysLeft days",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  displayOption == 0
                      ? "since pregnancy"
                      : "to baby born",
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onOptionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Pregnancy option",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Trimester Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: mainPink.withOpacity(0.06),
                  blurRadius: 13,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trimester,
                  style: TextStyle(
                    fontSize: 15,
                    color: mainPink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${weeks} weeks",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "$daysLeft days to baby born",
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 13,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDFE9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: t1Progress.clamp(0, 1),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: mainPink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 14,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6E4F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: t2Progress.clamp(0, 1),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB1BDFB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 13,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7C6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: t3Progress.clamp(0, 1),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB35AFF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('T1', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('T2', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('T3', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          myCyclesCard(periodLength, cycleLength),
        ],
      ),
    );
  }

  Widget myCyclesCard(int periodLength, int cycleLength) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(
          vertical: 15, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "My cycles",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 0),
                  child: Column(
                    children: [
                      Text(
                        "$periodLength Days",
                        style: TextStyle(
                            color: Colors.pink.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Average period",
                        style: TextStyle(
                            color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6CB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 0),
                  child: Column(
                    children: [
                      Text(
                        "$cycleLength Days",
                        style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Average cycle",
                        style: TextStyle(
                            color: Colors.black54, fontSize: 13),
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

class InteractiveTimelineCard extends StatelessWidget {
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final DateTime ovulationDay;
  final DateTime cycleEnd;
  final DateTime today;
  final int currentCycleDay;
  final int? selectedDayIdx;
  final Function(int) onDayTap;

  const InteractiveTimelineCard({
    super.key,
    required this.periodStart,
    required this.periodEnd,
    required this.fertileStart,
    required this.fertileEnd,
    required this.ovulationDay,
    required this.cycleEnd,
    required this.today,
    required this.currentCycleDay,
    required this.selectedDayIdx,
    required this.onDayTap,
  });

  String _chanceStr(DateTime day) {
    if (!day.isBefore(periodStart) && !day.isAfter(periodEnd)) return "LOW";
    if (!day.isBefore(fertileStart) && !day.isAfter(fertileEnd)) return "HIGH";
    if (day.isAfter(fertileEnd) && day.isBefore(fertileEnd.add(const Duration(days: 4)))) {
      return "MEDIUM";
    }
    return "LOW";
  }

  Color _chanceColor(String chance) {
    switch (chance) {
      case "HIGH":
        return Colors.orange;
      case "MEDIUM":
        return Colors.deepPurple;
      case "LOW":
      default:
        return Colors.pink.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = cycleEnd.difference(periodStart).inDays + 1;
    final todayIdx = today.difference(periodStart).inDays.clamp(0, totalDays - 1);

    // Which day is selected? If none, show today.
    int displayDayIdx = selectedDayIdx ?? todayIdx;
    DateTime displayDay = periodStart.add(Duration(days: displayDayIdx));
    int displayCycleDay = displayDay.difference(periodStart).inDays + 1;
    final chance = _chanceStr(displayDay);

    // Timeline bar constants
    const segmentWidth = 18.0;
    final timelineWidth = segmentWidth * totalDays;

    final bigDate = DateFormat.MMMd().format(displayDay);
    final boldTitle = "$bigDate - Cycle Day $displayCycleDay";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large bold title line
          Text(
            boldTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Chance line
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              "$chance - Chance of getting pregnant",
              style: TextStyle(
                color: _chanceColor(chance),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Timeline with marker
          SizedBox(
            height: 60,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: timelineWidth,
                      child: Stack(
                        children: [
                          Row(
                            children: List.generate(totalDays, (i) {
                              DateTime barDay = periodStart.add(Duration(days: i));
                              String ch = _chanceStr(barDay);
                              return GestureDetector(
                                onTap: () => onDayTap(i),
                                child: Container(
                                  width: segmentWidth,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _chanceColor(ch).withOpacity(0.7),
                                    borderRadius: i == 0
                                        ? const BorderRadius.horizontal(left: Radius.circular(7))
                                        : i == totalDays - 1
                                        ? const BorderRadius.horizontal(right: Radius.circular(7))
                                        : BorderRadius.zero,
                                  ),
                                ),
                              );
                            }),
                          ),
                          // Ovulation marker
                          Positioned(
                            left: ((ovulationDay.difference(periodStart).inDays + 0.5) * segmentWidth) - 9,
                            top: -19,
                            child: Column(
                              children: [
                                Icon(Icons.blur_circular, color: Colors.orange, size: 18),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          // Day marker (circle with border)
                          Positioned(
                            left: displayDayIdx * segmentWidth + (segmentWidth / 2) - 24,
                            top: 13,
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: _chanceColor(chance),
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _chanceColor(chance).withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                "Day\n$displayCycleDay",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _chanceColor(chance),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Period start marker
                Positioned(
                  left: 0,
                  top: 41,
                  child: Text(
                    DateFormat.MMMd().format(periodStart),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFBDBDBD),
                        fontWeight: FontWeight.w500),
                  ),
                ),
                // Cycle end marker
                Positioned(
                  right: 0,
                  top: 41,
                  child: Text(
                    DateFormat.MMMd().format(cycleEnd),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFBDBDBD),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}