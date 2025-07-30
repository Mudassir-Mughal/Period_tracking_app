import 'package:calender_app/screens/question3.dart';
import 'package:calender_app/screens/reminder.dart';
import 'package:calender_app/screens/settings.dart';
import 'package:calender_app/screens/calender.dart';
import 'package:calender_app/screens/pregnancysetupscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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

    setState(() {
      _isLoaded = true;
    });
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

  void goToQuestion3({DateTime? focusDay}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnboardStep3(periodLength: periodLength, cycleLength: cycleLength),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Text(
            "No period data found. Please set your period info in settings.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(theme.backgroundImage, fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header (aligned with Calendar and other pages)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 0,
                      left: 2,
                      right: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: theme.accentColor,
                            size: 28,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                            await _loadAllUserData();
                          },
                        ),
                        Text(
                          'Period Tracker',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.notifications,
                            color: theme.accentColor,
                            size: 28,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RemindersScreen(),
                              ),
                            );
                            await _loadAllUserData();
                          },
                          splashRadius: 28,
                        ),
                      ],
                    ),
                  ),
                  // ...rest of your widgets


                  // Today's Status Circle with proper shape
                  // Replace the existing circle container with this code
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hexagon shape image
                      Image.asset(
                        'assets/homeicon.png', // Your hexagon image path
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),

                      // Pink accent line (bottom left curve)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: CustomPaint(size: Size(140, 140)),
                      ),

                      // Content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Today',
                            style: GoogleFonts.poppins(
                              color: theme.accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0),
                          Text(
                            isOnPeriod
                                ? 'Period Day'
                                : (DateTime.now().isAtSameMomentAs(
                                        ovulationDay!,
                                      )
                                      ? 'Ovulation Day'
                                      : (DateTime.now().isAfter(
                                                  fertileStart!,
                                                ) &&
                                                DateTime.now().isBefore(
                                                  fertileEnd!,
                                                )
                                            ? 'Fertile Day'
                                            : 'Normal Day')),
                            style: GoogleFonts.poppins(
                              color: theme.accentColor,
                              fontSize: 20,
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Edit Period Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => goToQuestion3(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentColor,
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

                  SizedBox(height: 12),

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
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
                                isOnPeriod
                                    ? 'Period Day'
                                    : (DateTime.now().isAtSameMomentAs(
                                            ovulationDay!,
                                          )
                                          ? 'Ovulation'
                                          : (DateTime.now().isAfter(
                                                      fertileStart!,
                                                    ) &&
                                                    DateTime.now().isBefore(
                                                      fertileEnd!,
                                                    )
                                                ? 'Fertile Day'
                                                : 'Normal Day')),
                                isOnPeriod
                                    ? Image.asset(
                                        'assets/cyclephase1.png',
                                        fit: BoxFit.contain,
                                      )
                                    : Image.asset(
                                        'assets/cyclephase2.png',
                                        fit: BoxFit.contain,
                                      ),
                                isOnPeriod
                                    ? theme.accentColor
                                    : (DateTime.now().isAtSameMomentAs(
                                            ovulationDay!,
                                          )
                                          ? Colors.orange
                                          : (DateTime.now().isAfter(
                                                      fertileStart!,
                                                    ) &&
                                                    DateTime.now().isBefore(
                                                      fertileEnd!,
                                                    )
                                                ? theme.accentColor
                                                : Colors.grey)),
                              ),

                              SizedBox(
                                width: 15,
                              ), // Added more space between boxes
                              // Fertile Window
                              _buildPhaseBox(
                                DateFormat('MMM d').format(fertileStart!),
                                'Fertility Window',
                                Image.asset('assets/cyclephase2.png'),
                                theme.accentColor,
                              ),
                              SizedBox(
                                width: 15,
                              ), // Added more space between boxes
                              // Next Period
                              _buildPhaseBox(
                                DateFormat('MMM d').format(nextPeriodDate!),
                                'Next Period',
                                Image.asset('assets/cyclephase3.png'),
                                theme.accentColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // Cycle Day Info
                  if (lastPeriodStart != null &&
                      cycleStart != null &&
                      cycleEnd != null &&
                      fertileStart != null &&
                      fertileEnd != null &&
                      ovulationDay != null &&
                      periodEnd != null)
                    InteractiveTimelineCard(
                      periodStart: cycleStart!,
                      periodEnd: periodEnd!,
                      fertileStart: fertileStart!,
                      fertileEnd: fertileEnd!,
                      ovulationDay: ovulationDay!,
                      cycleEnd: cycleEnd!,
                      today: DateTime.now(),
                      currentCycleDay: currentCycleDay,
                      selectedDayIdx: selectedDayIdx,
                      onDayTap: (int idx) {
                        setState(() {
                          selectedDayIdx = idx;
                        });
                      },
                      periodLength: periodLength,
                      cycleLength: cycleLength,
                    ),

                  SizedBox(height: 12),

                  SizedBox(height: 12), // Added bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBox(String date, String title, Widget image, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
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

          // ✅ Injected image widget (with fixed size wrapper)
          SizedBox(width: 28, height: 28, child: image),

          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.grey[800], fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // PREGNANCY HOME WIDGET (no cat image, compact and clean)
  Widget pregnancyHomeWidget(
      BuildContext context,
      DateTime startDate,
      int displayOption,
      VoidCallback onOptionTap,
      ) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
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
    double t3Progress = (weeks >= 27) ? ((weeks - 27) + days / 7) / 13 : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              theme.backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // --- Custom top bar like Report page ---
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 10, right: 10),
                  child: Row(
                    children: [
                      Text(
                        'Home',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                          await _loadAllUserData();
                          // ignore: invalid_use_of_protected_member
                          (context as Element).markNeedsBuild();
                        },
                        splashRadius: 28,
                        color: mainPink,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      Text(
                        displayOption == 0 ? "${weeks}W${days}D" : "$daysLeft days",
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        displayOption == 0 ? "since pregnancy" : "to baby born",
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onOptionTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Pregnancy option",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: mainPink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "${weeks} weeks",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "$daysLeft days to baby born",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
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
                        children: [
                          Text(
                            'T1',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'T2',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'T3',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                myCyclesCard(periodLength, cycleLength),
                // Remove bottom padding/SizedBox to avoid white line
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:  [
              Text(
                "My cycles",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
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
                    vertical: 16,
                    horizontal: 0,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$periodLength Days",
                        style: GoogleFonts.poppins(
                          color: Colors.pink.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                       Text(
                        "Average period",
                        style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
  final int cycleLength;
  final int periodLength;

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
    required this.cycleLength,
    required this.periodLength,
  });

  String _chanceStr(DateTime day) {
    if (!day.isBefore(periodStart) && !day.isAfter(periodEnd)) return "LOW";
    if (!day.isBefore(fertileStart) && !day.isAfter(fertileEnd)) return "HIGH";
    if (day.isAfter(fertileEnd) &&
        day.isBefore(fertileEnd.add(const Duration(days: 4)))) {
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
    final todayIdx = today
        .difference(periodStart)
        .inDays
        .clamp(0, totalDays - 1);

    int displayDayIdx = selectedDayIdx ?? todayIdx;
    DateTime displayDay = periodStart.add(Duration(days: displayDayIdx));
    int displayCycleDay = displayDay.difference(periodStart).inDays + 1;
    final chance = _chanceStr(displayDay);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${DateFormat('MMM d').format(displayDay)} - Cycle Day $displayCycleDay",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 2),

          Text(
            "$chance Chance of Pregnancy",
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          SizedBox(height: 12),

          Stack(
            clipBehavior: Clip.none,
            children: [
              // White background for gaps
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Timeline segments with gaps
              Row(
                children: [
                  // Period phase (Low chance)
                  Expanded(
                    flex: periodLength,
                    child: Container(
                      margin: EdgeInsets.only(right: 2), // Gap
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFFD6BA2),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(5),
                          right: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  // Fertile phase (High chance)
                  Expanded(
                    flex: 7,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 2,
                      ), // Gaps on both sides
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFB847),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  // Post-fertile phase (Medium chance)
                  Expanded(
                    flex: cycleLength - periodLength - 7,
                    child: Container(
                      margin: EdgeInsets.only(left: 2), // Gap
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE5EC),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(5),
                          right: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Day marker on top
              // Replace both Positioned widgets with this single one
              Positioned(
                left:
                    (displayDayIdx / totalDays) *
                    (MediaQuery.of(context).size.width - 100),
                bottom: -40, // Adjusted position to be below timeline
                child: Column(
                  children: [
                    Container(width: 1, height: 20, color: Colors.black),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${displayCycleDay} Day',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20), // Space for date marker
          // Gesture detector for timeline interaction
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final percentage = (localPosition.dx / box.size.width).clamp(
                0.0,
                1.0,
              );
              final newDayIdx = (percentage * totalDays).round();
              if (newDayIdx >= 0 && newDayIdx < totalDays) {
                onDayTap(newDayIdx);
              }
            },
            onTapDown: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final percentage = (localPosition.dx / box.size.width).clamp(
                0.0,
                1.0,
              );
              final newDayIdx = (percentage * totalDays).round();
              if (newDayIdx >= 0 && newDayIdx < totalDays) {
                onDayTap(newDayIdx);
              }
            },
            child: Container(height: 30, color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}
