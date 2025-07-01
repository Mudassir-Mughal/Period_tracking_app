import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PregnancySetupScreen extends StatefulWidget {
  const PregnancySetupScreen({super.key});

  @override
  State<PregnancySetupScreen> createState() => _PregnancySetupScreenState();
}

class _PregnancySetupScreenState extends State<PregnancySetupScreen> {
  DateTime selectedStartDate = DateTime.now();
  int selectedOption = 0; // 0 = since pregnancy, 1 = countdown

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDateStr = prefs.getString('pregnancyStartDate');
    final storedOption = prefs.getInt('pregnancyDisplayOption');

    if (storedDateStr != null) {
      setState(() {
        selectedStartDate = DateTime.parse(storedDateStr);
      });
    }
    if (storedOption != null) {
      setState(() {
        selectedOption = storedOption;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainPink = const Color(0xFFFD6BA2);
    final dueDate = selectedStartDate.add(const Duration(days: 280));
    final daysLeft = dueDate.difference(DateTime.now()).inDays;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Pregnancy",
          style: TextStyle(
            color: mainPink,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        iconTheme: IconThemeData(color: mainPink),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFDF3F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🎉 Congratulations Text
            Center(
              child: Column(
                children: [
                  const Icon(Icons.cake, size: 80, color: Color(0xFFFD6BA2)),
                  const SizedBox(height: 20),
                  Text(
                    '🎉 Congratulations!',
                    style: TextStyle(
                      color: mainPink,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Count down the days until your baby arrives!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            /// 📅 Estimated Start
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                title: const Text("Estimated start of gestation"),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(selectedStartDate),
                  style: const TextStyle(color: Colors.blue),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedStartDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: mainPink,
                            onPrimary: Colors.white,
                            onSurface: mainPink,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: mainPink,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedStartDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Display on the homepage",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  RadioListTile<int>(
                    title: const Text("0W1D since pregnancy"),
                    value: 0,
                    groupValue: selectedOption,
                    onChanged: (val) => setState(() => selectedOption = val!),
                    activeColor: mainPink,
                  ),
                  RadioListTile<int>(
                    title: const Text("Countdown (days left)"),
                    value: 1,
                    groupValue: selectedOption,
                    onChanged: (val) => setState(() => selectedOption = val!),
                    activeColor: mainPink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            /// 🔴 Turn Off Pregnancy Mode
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('pregnancyMode', false);
                await prefs.remove('pregnancyStartDate');
                await prefs.remove('pregnancyDisplayOption');
                if (!mounted) return;
                Navigator.pop(context, false); // Return false to indicate turn off
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pregnancy mode turned OFF')),
                );
              },
              child: const Text(
                "Turn off pregnancy mode",
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// ✅ Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('pregnancyMode', true);
                  await prefs.setString('pregnancyStartDate', selectedStartDate.toIso8601String());
                  await prefs.setInt('pregnancyDisplayOption', selectedOption);

                  if (!mounted) return;
                  Navigator.pop(context, true); // Return true to indicate saved
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pregnancy mode saved')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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