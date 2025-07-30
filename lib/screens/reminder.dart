import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<String> reminderKeys = [
    'remind_period_start',
    'remind_period_end',
    'remind_note',
    'remind_fertility',
    'remind_ovulation',
  ];
  final Map<String, String> reminderNames = {
    'remind_period_start': "Period Start",
    'remind_period_end': "Period ends",
    'remind_note': "Note reminder",
    'remind_fertility': "Fertility reminder",
    'remind_ovulation': "Ovulation reminder",
  };
  final Map<String, String> reminderDescriptions = {
    'remind_period_start': "Period first day reminder",
    'remind_period_end': "Period last day reminder",
    'remind_note': "Reminds your note",
    'remind_fertility': "Remind you first fertile day",
    'remind_ovulation': "Remind you ovulation day",
  };
  final Map<String, String> defaultMessages = {
    'remind_period_start': "Your periods start from today",
    'remind_period_end': "Period is over? Last day of your period.",
    'remind_note': "Don't forget you added a note about today",
    'remind_fertility': "Fertile days are start from today",
    'remind_ovulation': "Ovulation day come.",
  };

  Map<String, bool> reminderEnabled = {};
  Map<String, TimeOfDay> reminderTime = {};
  Map<String, String> reminderMsg = {};

  String? editingTimeKey;

  final Color mainPink = const Color(0xFFFD6BA2);
  final Color accentPurple = const Color(0xFFB35AFF);
  final Color lightPink = const Color(0xFFF9F3FF);
  final Color cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _initNotifications().then((_) {
      _loadPrefs();
      requestBatteryOptimizationPermission();
    });
  }

  Future<void> requestBatteryOptimizationPermission() async {
    if (Platform.isAndroid) {
      final platform = MethodChannel('awesome_notifications');
      try {
        await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      } catch (e) {
        print('Battery optimization exception: $e');
      }
    }
  }

  void requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      bool requested = await AwesomeNotifications()
          .requestPermissionToSendNotifications();
      if (!requested) {
        AwesomeNotifications().showNotificationConfigPage();
      }
    }
  }

  Future<void> _initNotifications() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'reminder_channel',
        channelName: 'Reminders',
        channelDescription: 'Channel for reminder notifications',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      ),
    ], debug: true);

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (!await AwesomeNotifications().isNotificationAllowed()) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    }
  }

  int _reminderId(String key) {
    switch (key) {
      case 'remind_period_start':
        return 101;
      case 'remind_period_end':
        return 102;
      case 'remind_note':
        return 103;
      case 'remind_fertility':
        return 104;
      case 'remind_ovulation':
        return 105;
      default:
        return 0;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, bool> loadedEnabled = {};
    Map<String, TimeOfDay> loadedTime = {};
    Map<String, String> loadedMsg = {};

    for (final key in reminderKeys) {
      loadedEnabled[key] =
          prefs.getBool(key) ?? false; // default OFF for first launch
      final timeStr = prefs.getString('${key}_time');
      if (timeStr != null) {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          loadedTime[key] = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        } else {
          loadedTime[key] = const TimeOfDay(hour: 8, minute: 0);
        }
      } else {
        loadedTime[key] = const TimeOfDay(hour: 8, minute: 0);
      }
      loadedMsg[key] =
          prefs.getString('${key}_msg') ?? defaultMessages[key] ?? "";
    }

    setState(() {
      reminderEnabled = loadedEnabled;
      reminderTime = loadedTime;
      reminderMsg = loadedMsg;
    });

    // Schedule all enabled reminders for the next relevant day
    for (final key in reminderKeys) {
      if (reminderEnabled[key] == true) {
        await _scheduleReminderNotification(key);
      } else {
        await _cancelReminderNotification(key);
      }
    }
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      reminderEnabled[key] = value;
    });
    if (value) {
      await _scheduleReminderNotification(key);
    } else {
      await _cancelReminderNotification(key);
    }
  }

  Future<void> _setTime(String key, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${key}_time', '${time.hour}:${time.minute}');
    setState(() {
      reminderTime[key] = time;
    });
    await _scheduleReminderNotification(key);
  }

  Future<void> _setMsg(String key, String msg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${key}_msg', msg);
    setState(() {
      reminderMsg[key] = msg;
    });
    if (reminderEnabled[key] == true) {
      await _scheduleReminderNotification(key);
    }
  }

  // Replace these with your actual logic for next relevant dates:
  DateTime? getNextPeriodStartDate() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  DateTime? getNextPeriodEndDate() {
    final today = DateTime.now();
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 4));
  }

  DateTime? getNextNoteDate() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  DateTime? getNextFertilityDate() {
    final today = DateTime.now();
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 10));
  }

  DateTime? getNextOvulationDate() {
    final today = DateTime.now();
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 14));
  }

  Future<void> _scheduleReminderNotification(String key) async {
    final id = _reminderId(key);
    final time = reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0);
    final msg = reminderMsg[key] ?? defaultMessages[key] ?? '';
    final title = reminderNames[key] ?? 'Reminder';

    // Cancel previous notification with this ID
    await AwesomeNotifications().cancel(id);

    // Determine correct day based on reminder type
    DateTime? day;
    if (key == 'remind_period_start') {
      day = getNextPeriodStartDate();
    } else if (key == 'remind_period_end') {
      day = getNextPeriodEndDate();
    } else if (key == 'remind_note') {
      day = getNextNoteDate();
    } else if (key == 'remind_fertility') {
      day = getNextFertilityDate();
    } else if (key == 'remind_ovulation') {
      day = getNextOvulationDate();
    }

    if (day == null) {
      debugPrint('[Reminder] No day found for key $key');
      return;
    }

    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      debugPrint(
        '[Reminder] Scheduled date $scheduledDate is in the past. Skipping.',
      );
      return;
    }

    debugPrint('[Reminder] Scheduling "$title" on $scheduledDate');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminder_channel',
        title: title,
        body: msg,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true, // Important for Android 12+
        allowWhileIdle: true, // Makes it work even if phone is idle
      ),
    );
  }

  Future<void> _cancelReminderNotification(String key) async {
    await AwesomeNotifications().cancel(_reminderId(key));
  }

  Widget _buildTimePicker(String key) {
    final TimeOfDay time =
        reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0);
    int selectedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    int selectedMinute = time.minute;
    String selectedPeriod = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hours = List.generate(12, (index) => index + 1);
    final minutes = List.generate(60, (index) => index);

    int hourIndex = hours.indexOf(selectedHour);
    int minuteIndex = minutes.indexOf(selectedMinute);
    int periodIndex = selectedPeriod == 'AM' ? 0 : 1;

    FixedExtentScrollController hourCtrl = FixedExtentScrollController(
      initialItem: hourIndex,
    );
    FixedExtentScrollController minCtrl = FixedExtentScrollController(
      initialItem: minuteIndex,
    );
    FixedExtentScrollController ampmCtrl = FixedExtentScrollController(
      initialItem: periodIndex,
    );

    return Container(
      margin: const EdgeInsets.only(top: 18, bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour Picker
                SizedBox(
                  width: 60,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 35,
                    diameterRatio: 1.5,
                    controller: hourCtrl,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (idx) {
                      selectedHour = hours[idx];
                      int hour = selectedHour % 12;
                      if (selectedPeriod == "PM") hour += 12;
                      if (hour == 24) hour = 0;
                      setState(() {
                        reminderTime[key] = TimeOfDay(
                          hour: hour,
                          minute: selectedMinute,
                        );
                      });
                      _setTime(
                        key,
                        reminderTime[key] ??
                            const TimeOfDay(hour: 8, minute: 0),
                      );
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (ctx, idx) {
                        if (idx < 0 || idx >= hours.length) return null;
                        return Center(
                          child: Text(
                            hours[idx].toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: hours[idx] == selectedHour
                                  ? Color(0xFFFFE6090)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                      childCount: hours.length,
                    ),
                  ),
                ),
                Text(
                  ":",
                  style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFFFFE6090),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Minute Picker
                SizedBox(
                  width: 60,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 35,
                    diameterRatio: 1.5,
                    controller: minCtrl,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (idx) {
                      selectedMinute = minutes[idx];
                      int hour = selectedHour % 12;
                      if (selectedPeriod == "PM") hour += 12;
                      if (hour == 24) hour = 0;
                      setState(() {
                        reminderTime[key] = TimeOfDay(
                          hour: hour,
                          minute: selectedMinute,
                        );
                      });
                      _setTime(
                        key,
                        reminderTime[key] ??
                            const TimeOfDay(hour: 8, minute: 0),
                      );
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (ctx, idx) {
                        if (idx < 0 || idx >= minutes.length) return null;
                        return Center(
                          child: Text(
                            minutes[idx].toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: minutes[idx] == selectedMinute
                                  ? Color(0xFFFFE6090)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                      childCount: minutes.length,
                    ),
                  ),
                ),
                // AM/PM Picker
                SizedBox(
                  width: 60,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 35,
                    diameterRatio: 1.5,
                    controller: ampmCtrl,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (idx) {
                      selectedPeriod = idx == 0 ? "AM" : "PM";
                      int hour = selectedHour % 12;
                      if (selectedPeriod == "PM") hour += 12;
                      if (hour == 24) hour = 0;
                      setState(() {
                        reminderTime[key] = TimeOfDay(
                          hour: hour,
                          minute: selectedMinute,
                        );
                      });
                      _setTime(
                        key,
                        reminderTime[key] ??
                            const TimeOfDay(hour: 8, minute: 0),
                      );
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (ctx, idx) {
                        if (idx < 0 || idx > 1) return null;
                        return Center(
                          child: Text(
                            idx == 0 ? 'AM' : 'PM',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color:
                                  ((idx == 0 && selectedPeriod == 'AM') ||
                                      (idx == 1 && selectedPeriod == 'PM'))
                                  ? Color(0xFFFFE6090)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                      childCount: 2,
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

  Widget _reminderCard(String key) {
    final enabled = reminderEnabled[key] ?? false;
    final time = reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: mainPink.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 15, right: 8),
            title: Text(
              reminderNames[key]!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              reminderDescriptions[key]!,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            value: enabled,
            activeColor: Color(0xFFFFE6090),
            onChanged: (v) async {
              await _setBool(key, v);
            },
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              child: Row(
                children: [
                  Text(
                    "Notification time",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        editingTimeKey = editingTimeKey == key ? null : key;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            time.format(context),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: editingTimeKey == key ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(
                              Icons.keyboard_arrow_down_sharp,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (enabled && editingTimeKey == key) _buildTimePicker(key),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE6EE), // Light pink
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(
              context,
            ); // This takes you back to the previous screen
          },
        ),
        title: Text(
          "Reminders",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
        leadingWidth: 50,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        children: [
          Text(
            "Period & Ovulation",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A276F).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          ...reminderKeys.map(_reminderCard).toList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
