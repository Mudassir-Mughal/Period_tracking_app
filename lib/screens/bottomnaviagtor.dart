import 'package:flutter/material.dart';
import 'Calender.dart';
import 'Report.dart';
import 'home.dart';
import 'addnote.dart';
 // Ensure this matches your file/class name

class MainScreen extends StatefulWidget {
  final int initialTab;
  const MainScreen({this.initialTab = 0, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    HomeScreen(),
    Calender(),
    AddNoteScreen(),
    Report()
     // Make sure your class name matches this
  ];

  @override
  void initState() {
    _currentIndex = widget.initialTab;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_rounded), label: "Add"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Report"),

        ],
        selectedItemColor: Color(0xFFFD6BA2),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

