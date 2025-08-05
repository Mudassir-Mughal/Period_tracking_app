import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

import 'bottomnaviagtor.dart';
import 'home.dart';
import 'settings.dart';
import 'reminder.dart';

class AddNoteScreen extends StatefulWidget {
  final DateTime? date;
  final String? existingNote;
  const AddNoteScreen({super.key, this.date, this.existingNote});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  DateTime selectedDate = DateTime.now();
  final Color primaryPink = const Color(0xFFFF4F8B);
  final TextEditingController _noteController = TextEditingController();
  String? selectedMood;
  int? selectedFlow;
  String? selectedIntercourse;
  double? selectedWeight;
  String? selectedWeightUnit;
  double? selectedTemperature;
  String? selectedTemperatureUnit;
  int selectedGlasses = 0;
  int glassMl = 250;
  int targetMl = 2000;
  List<int> symptomStars = [0, 0, 0, 0];
  String selectedCondomOption = '';
  String selectedOrgasm = '';
  int intercourseTimes = 0;


  final List<String> symptomNames = [
    "back pain",
    "Anxiety",
    "Headache",
    "Cravings",
  ];
  final List<String> symptomAssetIcons = [
    "assets/backpain.png",
    "assets/Anxiety.png",
    "assets/Headache.png",
    "assets/cravings.png",
  ];





  final List<Map<String, String>> moods = [
    {"emoji": "😇", "label": "Angelic"},
    {"emoji": "😠", "label": "Angry"},
    {"emoji": "😰", "label": "Anxious"},
    {"emoji": "😢", "label": "Ashamed"},
    {"emoji": "😊", "label": "Happy"},
    {"emoji": "😔", "label": "Sad"},
    {"emoji": "😎", "label": "Confident"},
    {"emoji": "😭", "label": "Crying"},
    {"emoji": "😴", "label": "Sleepy"},
    {"emoji": "😤", "label": "Frustrated"},
    {"emoji": "😍", "label": "In Love"},
    {"emoji": "🤒", "label": "Sick"},
  ];
  List<bool> selectedFlowDrops = [false, false, false, false];




  final Map<String, IconData> protectionIcons = {
    'Protected': Icons.security,
    'Unprotected': Icons.block,
  };

  final Map<String, IconData> orgasmIcons = {
    'Yes': Icons.favorite,
    'No': Icons.heart_broken,
  };

  final Map<String, IconData> timesIcons = {
    '0': Icons.exposure_zero,
    '1': Icons.looks_one,
    '2': Icons.looks_two,
    '3': Icons.looks_3,
    '4': Icons.looks_4,
    '5': Icons.looks_5,
  };

  String selectedUnit = 'kg';
  double inputValue = 0.0;

  void _showMoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  'Select Mood',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: moods.map((mood) {
                    return GestureDetector(
                      onTap: () {
                        selectedMood = mood["emoji"];
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood["emoji"]!,
                            style:  GoogleFonts.poppins(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood["label"]!,
                            style: GoogleFonts.poppins(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWaterSettingsDialog(BuildContext context, StateSetter parentSetState) {
    final glassController = TextEditingController(text: glassMl.toString());
    final targetController = TextEditingController(text: targetMl.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Water Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Daily Target (ml)'),
              ),
              TextField(
                controller: glassController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Glass Size (ml)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFD6BA2)),
              onPressed: () {
                int? newTarget = int.tryParse(targetController.text);
                int? newGlass = int.tryParse(glassController.text);
                if (newTarget != null && newGlass != null && newTarget > 0 && newGlass > 0) {
                  parentSetState(() {
                    targetMl = newTarget;
                    glassMl = newGlass;
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void showInputDialog(BuildContext context, String type) {
    // If temperature dialog, input value is 0.0 and default unit is °C
    // Else, use the existing value/unit for weight
    double dialogInputValue =
    type == 'Temperature' ? 0.0 : inputValue;
    String dialogSelectedUnit =
    type == 'Temperature' ? '°C' : selectedUnit;

    TextEditingController controller =
    TextEditingController(text: dialogInputValue.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(10),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unit toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => dialogSelectedUnit = type == 'Weight' ? 'kg' : '°C'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: dialogSelectedUnit == (type == 'Weight' ? 'kg' : '°C')
                                  ? const Color(0xFFFDC1DC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(type == 'Weight' ? 'kg' : '°C',
                                style: const TextStyle(color: Colors.black)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => dialogSelectedUnit = type == 'Weight' ? 'lb' : '°F'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: dialogSelectedUnit == (type == 'Weight' ? 'lb' : '°F')
                                  ? const Color(0xFFFDC1DC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(type == 'Weight' ? 'lb' : '°F',
                                style: const TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Value counter and manual entry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Color(0xFFFD6BA2)),
                        onPressed: () {
                          setState(() {
                            if (dialogInputValue > 0) dialogInputValue -= 0.5;
                            controller.text = dialogInputValue.toStringAsFixed(2);
                          });
                        },
                      ),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        color: const Color(0xFFFEDFE8),
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style:  GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(border: InputBorder.none),
                          inputFormatters: [
                            // Only allow numbers and at most one decimal point
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              if ('.'.allMatches(newValue.text).length > 1) {
                                return oldValue;
                              }
                              return newValue;
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              dialogInputValue = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFFFD6BA2)),
                        onPressed: () {
                          setState(() {
                            dialogInputValue += 0.5;
                            controller.text = dialogInputValue.toStringAsFixed(2);
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Confirm button
                  SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFD6BA2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (type == 'Weight') {
                            selectedWeight = dialogInputValue;
                            selectedWeightUnit = dialogSelectedUnit;
                          } else {
                            selectedTemperature = dialogInputValue;
                            selectedTemperatureUnit = dialogSelectedUnit;
                          }
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
                          child: Text("Save", style: GoogleFonts.poppins(color: Colors.white , fontSize: 12 , fontWeight: FontWeight.bold)),
                        ),
                      )
                  ),
                  SizedBox(height: 10),

                ],
              );
            },
          ),
        );
      },
    );
  }



  Future<void> _saveNote() async {
    final trimmedNote = _noteController.text.trim();

    if (trimmedNote.isEmpty &&
        selectedMood == null &&
        selectedWeight == null &&
        selectedTemperature == null &&
        selectedFlow == null &&
        selectedIntercourse == null &&
        selectedGlasses == 0 &&
        symptomStars.every((star) => star == 0)) { // Also check symptoms
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some  data.'),
          backgroundColor: Color(0xFFFD6BA2),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String key = DateFormat('yyyy-MM-dd').format(selectedDate);

    if (trimmedNote.isNotEmpty) {
      await prefs.setString('note_$key', trimmedNote);
    }
    if (selectedMood != null) {
      await prefs.setString('mood_$key', selectedMood!);
    }
    if (selectedFlow != null) {
      await prefs.setInt('flow_$key', selectedFlow!);
    }
    if (selectedCondomOption.isNotEmpty) {
      await prefs.setString('condom_$key', selectedCondomOption);
    }
    if (selectedOrgasm.isNotEmpty) {
      await prefs.setString('orgasm_$key', selectedOrgasm);
    }
    await prefs.setInt('intercourseTimes_$key', intercourseTimes);

    // Save weight and temperature
    if (selectedWeight != null) {
      await prefs.setDouble('weight_$key', selectedWeight!);
    }
    if (selectedTemperature != null) {
      await prefs.setDouble('temperature_$key', selectedTemperature!);
    }

    // Save water intake details
    await prefs.setInt('waterGlasses_$key', selectedGlasses);
    await prefs.setInt('glassMl_$key', glassMl);
    await prefs.setInt('targetMl_$key', targetMl);
    await prefs.setInt('waterIntake_$key', selectedGlasses * glassMl);

    // Save symptoms stars as JSON string
    await prefs.setString('symptomStars_$key', jsonEncode(symptomStars));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note saved! Water: ${selectedGlasses * glassMl} ml'),
        backgroundColor: const Color(0xFFFD6BA2),
      ),
    );

    _noteController.clear();
    setState(() {
      selectedMood = null;
      selectedWeight = null;
      selectedTemperature = null;
      selectedGlasses = 0;
      symptomStars = [0, 0, 0, 0];
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainScreen(initialTab: 1)),
          (route) => false,
    );
  }


  Future<void> _showIntercourseDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String selectedCondomOption = "";
        String selectedOrgasm = "";
        int intercourseTimes = 0;

        // Asset image paths for your options
        final condomIcons = {
          "Protected": "assets/protected.png",
          "Unprotected": "assets/unprotected.png",
        };
        final orgasmIcons = {
          "Yes": "assets/orgasm_yes.png",
          "No": "assets/orgasm_no.png",
        };

        // Helper for multi-color icons
        Widget assetWithSelection(String path, bool selected) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(
              color: selected ? Color(0xFFFD6BA2) : Colors.transparent,
              width: 2,
            ),
          ),
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Image.asset(
            path,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
        );

        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(40),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Text("Condom option", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["Protected", "Unprotected"].map((option) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() => selectedCondomOption = option);
                        },
                        child: Column(
                          children: [
                            assetWithSelection(
                              condomIcons[option]!,
                              selectedCondomOption == option,
                            ),
                            const SizedBox(height: 4),
                            Text(option,
                              style: GoogleFonts.poppins(fontSize: 11),),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  Text("Female orgasm", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["Yes", "No"].map((option) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() => selectedOrgasm = option);
                        },
                        child: Column(
                          children: [
                            assetWithSelection(
                              orgasmIcons[option]!,
                              selectedOrgasm == option,
                            ),
                            const SizedBox(height: 4),
                            Text(option,
                              style: GoogleFonts.poppins(fontSize: 11),),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  Text("Times", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Color(0xFFFD6BA2), size: 30,),
                        onPressed: () {
                          if (intercourseTimes > 0) {
                            setStateDialog(() => intercourseTimes--);
                          }
                        },
                      ),
                      SizedBox(width: 20),
                      Text(
                        intercourseTimes.toString(),
                        style:  GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFFFD6BA2), size: 30,),
                        onPressed: () {
                          setStateDialog(() => intercourseTimes++);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFD6BA2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        "condom": selectedCondomOption,
                        "orgasm": selectedOrgasm,
                        "times": intercourseTimes,
                      });
                    },
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Text("Save",style: GoogleFonts.poppins(color: Colors.white),)
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
    if (result != null) {
      setState(() {
        selectedCondomOption = result['condom'] ?? '';
        selectedOrgasm = result['orgasm'] ?? '';
        intercourseTimes = result['times'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

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
                        "Add note",
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      // ...rest of your widgets (start from "Select Date" and below)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Select Date",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),

                      // (keep the rest of your widgets unchanged)
                      // ...

                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 90),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFFD6BA2),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFFFD6BA2),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Color(0xFFFD6BA2),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() => selectedDate = pickedDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat.yMMMMd().format(selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🌊 Flow Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Flow",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(4, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  for (int i = 0; i < selectedFlowDrops.length; i++) {
                                    selectedFlowDrops[i] = i <= index;
                                  }
                                  selectedFlow = index + 1; // 1 to 4 drops
                                });
                              },

                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Icon(
                                  Icons.water_drop,
                                  size: 20,
                                  color: selectedFlowDrops[index]
                                      ? const Color(0xFFFD6BA2) // Selected = pink
                                      : Colors.grey.shade300,   // Unselected = light grey
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

// 📝 Note Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Note",
                          style:GoogleFonts.poppins (
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (selectedMood != null)
                          Text(
                            selectedMood!,
                            style: const TextStyle(fontSize: 28),
                          ),
                        TextField(
                          controller: _noteController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: "Write something",hintStyle: TextStyle(fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

// ❤️ Intercourse Section
                      GestureDetector(
                        onTap: () => _showIntercourseDialog(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Intercourse",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Condom Option Icon & Text
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.pink[50], // Always pink background
                                          border: Border.all(
                                            color: selectedCondomOption.isNotEmpty
                                                ? Color(0xFFFD6BA2)
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Image.asset(
                                          selectedCondomOption == "Protected"
                                              ? "assets/protected.png"
                                              : selectedCondomOption == "Unprotected"
                                              ? "assets/unprotected.png"
                                              : "assets/protected.png", // fallback image
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.contain,
                                           // Grey icon if not selected
                                          colorBlendMode: selectedCondomOption.isNotEmpty ? null : BlendMode.saturation, // Greyscale blend if not selected
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedCondomOption.isNotEmpty ? selectedCondomOption : "Condom",
                                        style: GoogleFonts.poppins(fontSize: 11),
                                      ),

                                    ],
                                  ),
                                  // Orgasm Option Icon & Text
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.pink[50],
                                          border: Border.all(
                                            color: selectedOrgasm.isNotEmpty ? Color(0xFFFD6BA2) : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Image.asset(
                                          selectedOrgasm == "Yes"
                                              ? "assets/orgasm_yes.png"
                                              : selectedOrgasm == "No"
                                              ? "assets/orgasm_no.png"
                                              : "assets/orgasm_yes.png", // fallback image
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.contain,
                                           // Grey out if not selected
                                          colorBlendMode: selectedOrgasm.isNotEmpty ? null : BlendMode.saturation,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(selectedOrgasm.isNotEmpty ? selectedOrgasm : "Orgasm",
                                        style: GoogleFonts.poppins(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  // Times Icon & Text
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.pink[50],

                                        ),
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Text(
                                          intercourseTimes.toString(),
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Times", style: GoogleFonts.poppins(fontSize: 11)),
                                    ],
                                  ),
                                  // Chevron at end
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () => _showIntercourseDialog(context),
                                    padding: EdgeInsets.only(right: 6, bottom: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                  // 😊 Moods
                  // 😊 Moods - Preview with 4 emojis and dialog button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Moods",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ...moods.take(4).map((mood) {
                                  return GestureDetector(
                                    onTap: () => _showMoodDialog(context),
                                    child: Column(
                                      children: [
                                        Text(
                                          selectedMood == mood["emoji"] ? selectedMood! : mood["emoji"]!,
                                          style: TextStyle(
                                            fontSize: 28,
                                            backgroundColor: selectedMood == mood["emoji"]
                                                ? const Color(0xFFFD6BA2).withOpacity(0.2)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          mood["label"]!,
                                          style: GoogleFonts.poppins(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(width: 2), // Spacing between emojis and chevron
                                // Chevron icon at the end
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () => _showMoodDialog(context),
                                  padding: EdgeInsets.only(right: 6,bottom: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
SizedBox(height: 10),


                      // Place this inside your AddNoteScreen build method where you want the symptoms card
                      //Symptoms card
                      // Place this where you want the symptoms card in your build method

                      // Place this inside your build method where you want the symptoms card

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: Colors.black.withOpacity(0.06),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Symptoms",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(4, (i) {
                                final isPink = symptomStars[i] > 0;
                                return Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Image.asset(
                                          symptomAssetIcons[i],
                                          width: 38,
                                          height: 38,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(4, (star) => GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              symptomStars[i] = star + 1;
                                            });
                                          },
                                          child: Icon(
                                            Icons.star,
                                            size: 14,
                                            color: star < symptomStars[i]
                                                ? Color(0xFFFD6BA2)
                                                : Colors.grey,
                                          ),
                                        )),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        symptomNames[i],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      // Weight Card
                      GestureDetector(
                        onTap: () => showInputDialog(context, 'Weight'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(
                                "Weight",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: const [
                                  Icon(Icons.monitor_weight, color: Color(0xFF6D5DF6)),
                                  SizedBox(width: 8),
                                  Icon(Icons.chevron_right, color: Colors.black45),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                  // Temperature card
                  GestureDetector(
                    onTap: () => showInputDialog(context, 'Temperature'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                            "Temperature",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,

                            ),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.thermostat, color: Color(0xFFFD6BA2)),
                              SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: Colors.black45),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                      // water card
                      GestureDetector(
                        onTap: () => _showWaterSettingsDialog(context, setState),
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            int maxGlasses = 20;
                            int totalGlasses = (selectedGlasses > 8) ? selectedGlasses : 8;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Drink water",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Progress Row
                                  Row(
                                    children: [
                                      Text(
                                        "${selectedGlasses * glassMl}",
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF6B46FD),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        "/ $targetMl ml",
                                        style: GoogleFonts.poppins(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Glasses grid
                                  SizedBox(
                                    height: ((totalGlasses / 4).ceil() * 120).toDouble(),
                                    child: GridView.builder(
                                      itemCount: totalGlasses,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 6,
                                        crossAxisSpacing: 6,
                                        childAspectRatio: 0.7,
                                      ),
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        bool glassSelected = index < selectedGlasses;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (index == totalGlasses - 1 && totalGlasses < maxGlasses) {
                                                selectedGlasses++;
                                              } else {
                                                selectedGlasses = index + 1;
                                              }
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 35,
                                                height: 45,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFFB8E8FF),
                                                      Color(0xFF93C8EF),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: glassSelected
                                                      ? Image.asset('assets/img.png', width: 26, height: 26)
                                                      : const Icon(Icons.add, color: Color(0xFF6B46FD), size: 20),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "$glassMl ml",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                  SizedBox(height: 2),


                  // 💾 Save Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          "Save",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
            ],),);
  }
}


