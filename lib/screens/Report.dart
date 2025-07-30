import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

import 'bottomnaviagtor.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  int cycleLength = 28;
  int periodLength = 5;
  List<Map<String, dynamic>> cycleHistory = [];
  String currentYear = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cycle and period lengths
    final cycleLen = prefs.getInt('cycleLength') ?? 28;
    final periodLen = prefs.getInt('periodLength') ?? 5;

    // Load cycle history
    final historyJson = prefs.getString('cycleHistory');
    List<Map<String, dynamic>> history = [];

    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson);
        history = decoded
            .map(
              (item) => {
                'date': DateTime.parse(item['date']),
                'length': item['length'],
              },
            )
            .toList();

        // Sort history by date
        history.sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
        );

        // Get the year of the most recent cycle
        if (history.isNotEmpty) {
          final lastDate = history.last['date'] as DateTime;
          currentYear = lastDate.year.toString();
        }
      } catch (e) {
        print('Error loading cycle history: $e');
      }
    }

    setState(() {
      cycleLength = cycleLen;
      periodLength = periodLen;
      cycleHistory = history;
    });
  }

  Future<void> _downloadReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Cycle Report', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Cycle Length: $cycleLength days'),
            pw.Text('Period Length: $periodLength days'),
            pw.SizedBox(height: 20),
            pw.Text('History:'),
            ...cycleHistory.map((cycle) {
              final date = DateFormat('MMM d, y').format(cycle['date']);
              return pw.Text('$date: ${cycle['length']} days');
            }),
          ],
        ),
      ),
    );

    try {
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'cycle_report.pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    final maxCycleLength = cycleHistory.isEmpty
        ? 35
        : cycleHistory
        .map((e) => e['length'] as int)
        .reduce((a, b) => a > b ? a : b);
    final chartMaxY = (maxCycleLength + 5).toDouble();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(theme.backgroundImage, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
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
                        'Report',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.download_outlined),
                        color: theme.accentColor,
                        onPressed: _downloadReport,
                        splashRadius: 28,
                      ),
                    ],
                  ),
                ),
                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Row(
                    children: [
                      _buildLegendItem(
                        color: Color(0xFF9D50DD),
                        label: 'Cycle Length',
                        value: '$cycleLength Days',
                      ),
                      SizedBox(width: 20),
                      _buildLegendItem(
                        color: theme.accentColor,
                        label: 'Period Length',
                        value: '$periodLength Days',
                      ),
                    ],
                  ),
                ),
                // Chart section
                SizedBox(
                  height: 220,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: cycleHistory.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 20,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No cycle data available yet\nComplete your first cycle to see the chart',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentYear,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: chartMaxY,
                                minY: 0,
                                groupsSpace: 8,
                                barTouchData: BarTouchData(
                                  enabled: false,
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 20,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < cycleHistory.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: Text(
                                              '${cycleHistory[value.toInt()]['length']}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                height: 1,
                                              ),
                                            ),
                                          );
                                        }
                                        return Text('');
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < cycleHistory.length) {
                                          final date = cycleHistory[value.toInt()]['date'] as DateTime;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  DateFormat('MMM').format(date),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                  ),
                                                ),
                                                Text(
                                                  date.day.toString(),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 10,
                                                    height: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false,
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false,
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 10,
                                  getDrawingHorizontalLine: (value) =>
                                      FlLine(
                                        color: Colors.grey[200]!,
                                        strokeWidth: 0.5,
                                      ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(
                                  cycleHistory.length,
                                      (index) => BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: cycleHistory[index]['length'].toDouble(),
                                        color: theme.accentColor,
                                        width: 18,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
