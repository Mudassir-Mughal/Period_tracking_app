import 'dart:io';
import 'package:flutter/material.dart';
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
    'remind_period_start': "Period starts",
    'remind_period_end': "Period ends",
    'remind_note': "Note reminder",
    'remind_fertility': "Fertility reminder",
    'remind_ovulation': "Ovulation reminder",
  };
  final Map<String, String> reminderDescriptions = {
    'remind_period_start': "Next Period - 1 day left",
    'remind_period_end': "Remind you to log period end",
    'remind_note': "Remind you to add a note",
    'remind_fertility': "Remind you before fertile days",
    'remind_ovulation': "Remind you before ovulation",
  };
  final Map<String, String> defaultMessages = {
    'remind_period_start': "Period is starting soon.",
    'remind_period_end': "Period is over? Log it and check cycle analysis now.",
    'remind_note': "Don't forget your period note.",
    'remind_fertility': "Fertile days are coming.",
    'remind_ovulation': "Ovulation is near.",
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
    });
  }

  Future<void> _initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'reminder_channel',
          channelName: 'Reminders',
          channelDescription: 'Reminders for period and ovulation',
          defaultColor: mainPink,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          soundSource: 'resource://raw/notification',
        ),
      ],
      debug: true,
    );

    // Android 13+ runtime permission handling
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        if (!await AwesomeNotifications().isNotificationAllowed()) {
          await AwesomeNotifications().requestPermissionToSendNotifications();
        }
      }
    } else {
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
      loadedEnabled[key] = prefs.getBool(key) ?? false; // default OFF for first launch
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
      loadedMsg[key] = prefs.getString('${key}_msg') ?? defaultMessages[key] ?? "";
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
    return DateTime(today.year, today.month, today.day).add(const Duration(days: 4));
  }
  DateTime? getNextNoteDate() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }
  DateTime? getNextFertilityDate() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).add(const Duration(days: 10));
  }
  DateTime? getNextOvulationDate() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).add(const Duration(days: 14));
  }

  Future<void> _scheduleReminderNotification(String key) async {
    final id = _reminderId(key);
    final time = reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0);
    final msg = reminderMsg[key] ?? defaultMessages[key] ?? '';
    final title = reminderNames[key] ?? 'Reminder';

    await AwesomeNotifications().cancel(id);

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
    if (day == null) return;

    final now = DateTime.now();
    DateTime scheduledDate = DateTime(day.year, day.month, day.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) return;

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
        preciseAlarm: true,
      ),
    );
  }

  Future<void> _cancelReminderNotification(String key) async {
    await AwesomeNotifications().cancel(_reminderId(key));
  }

  Widget _buildTimePicker(String key) {
    final TimeOfDay time = reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0);
    int selectedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    int selectedMinute = time.minute;
    String selectedPeriod = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hours = List.generate(12, (index) => index + 1);
    final minutes = List.generate(60, (index) => index);

    int hourIndex = hours.indexOf(selectedHour);
    int minuteIndex = minutes.indexOf(selectedMinute);
    int periodIndex = selectedPeriod == 'AM' ? 0 : 1;

    FixedExtentScrollController hourCtrl = FixedExtentScrollController(initialItem: hourIndex);
    FixedExtentScrollController minCtrl = FixedExtentScrollController(initialItem: minuteIndex);
    FixedExtentScrollController ampmCtrl = FixedExtentScrollController(initialItem: periodIndex);

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
                        reminderTime[key] = TimeOfDay(hour: hour, minute: selectedMinute);
                      });
                      _setTime(key, reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0));
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
                                  ? accentPurple
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                      childCount: hours.length,
                    ),
                  ),
                ),
                Text(":", style: TextStyle(fontSize: 28, color: accentPurple, fontWeight: FontWeight.bold)),
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
                        reminderTime[key] = TimeOfDay(hour: hour, minute: selectedMinute);
                      });
                      _setTime(key, reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0));
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
                                  ? accentPurple
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
                        reminderTime[key] = TimeOfDay(hour: hour, minute: selectedMinute);
                      });
                      _setTime(key, reminderTime[key] ?? const TimeOfDay(hour: 8, minute: 0));
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
                              color: ((idx == 0 && selectedPeriod == 'AM') || (idx == 1 && selectedPeriod == 'PM'))
                                  ? accentPurple
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
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
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 15, right: 8, top: 10),
            title: Text(
              reminderNames[key]!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: mainPink,
                fontSize: 17,
              ),
            ),
            subtitle: Text(
              reminderDescriptions[key]!,
              style: TextStyle(
                color: accentPurple.withOpacity(0.8),
                fontSize: 13.5,
              ),
            ),
            value: enabled,
            activeColor: accentPurple,
            onChanged: (v) async {
              await _setBool(key, v);
            },
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 8, top: 8, bottom: 10),
              child: Row(
                children: [
                  Text(
                    "Notification time",
                    style: TextStyle(
                        color: accentPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        editingTimeKey = editingTimeKey == key ? null : key;
                      });
                    },
                    child: Text(
                      time.format(context),
                      style: TextStyle(
                        color: accentPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
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
      backgroundColor: lightPink,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: mainPink),
        centerTitle: true,
        title: const Text(
          "Reminders",
          style: TextStyle(
            color: Color(0xFFFD6BA2),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        children: [
          Text(
            "Period & Ovulation",
            style: TextStyle(
                color: accentPurple.withOpacity(0.7),
                letterSpacing: 0.1,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(height: 6),
          ...reminderKeys.map(_reminderCard).toList(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainPink,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}