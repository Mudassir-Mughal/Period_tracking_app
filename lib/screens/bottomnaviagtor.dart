import 'package:flutter/material.dart';
import 'Calender.dart';
import 'Report.dart';
import 'home.dart';
import 'addnote.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  final DateTime? editNoteDate;
  final String? editNoteText;

  const MainScreen({
    this.initialTab = 0,
    super.key,
    this.editNoteDate,
    this.editNoteText,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    _currentIndex = widget.initialTab;
    super.initState();
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex == 0) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Exit App'),
          content: Text('Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        ),
      );
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
      return false; // Don't pop automatically
    } else {
      // If on any other tab, go to Home tab
      setState(() {
        _currentIndex = 0;
      });
      return false; // Prevent pop
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(),
            Calender(),
            AddNoteScreen(
              date: widget.editNoteDate,
              existingNote: widget.editNoteText,
            ),
            Report(),
          ],
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
      ),
    );
  }
}