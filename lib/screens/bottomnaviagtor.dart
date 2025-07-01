import 'package:flutter/material.dart';
import 'home.dart';
import 'addnote.dart';
import 'Calender.dart'; // Ensure this matches your file/class name

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
    AddNoteScreen(),
    Calender(), // Make sure your class name matches this
  ];

  @override
  void initState() {
    _currentIndex = widget.initialTab;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Add"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Calendar"),
        ],
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}