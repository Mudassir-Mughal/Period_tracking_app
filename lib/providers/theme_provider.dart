import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeOption _currentTheme;

  ThemeProvider() : _currentTheme = defaultTheme {
    loadTheme(); // Load theme when provider is created
  }

  static final ThemeOption defaultTheme = ThemeOption(
    name: "Floral Blue",
    backgroundColor: Color(0xFFE6F4FF),
    cardColor: Colors.white,
    accentColor: Color(0xFFFD6BA2),
    description: "Light blue theme with flower decoration",
    backgroundImage: "assets/Theme 4.png",
  );

  ThemeOption get currentTheme => _currentTheme;

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('selectedTheme') ?? 0;
      if (themeIndex >= 0 && themeIndex < themeOptions.length) {
        _currentTheme = themeOptions[themeIndex];
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> setTheme(ThemeOption theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = themeOptions.indexOf(theme);
      if (index != -1) {
        await prefs.setInt('selectedTheme', index);
        _currentTheme = theme;
        notifyListeners();
      }
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  static final List<ThemeOption> themeOptions = [
    ThemeOption(
      name: "Floral Blue",
      backgroundColor: Color(0xFFE6F4FF),
      cardColor: Colors.white,
      accentColor: Color(0xFFFD6BA2),
      description: "Light blue theme with flower decoration",
      backgroundImage: "assets/Theme 4.png",
    ),
    ThemeOption(
      name: "Cherry Blossom",
      backgroundColor: Color(0xFFFFE6EE),
      cardColor: Colors.white,
      accentColor: Color(0xFFFD6BA2),
      description: "Pink theme with cherry blossom decoration",
      backgroundImage: "assets/Theme 2.png",
    ),
    ThemeOption(
      name: "Purple Waves",
      backgroundColor: Color(0xFFF3E6FF),
      cardColor: Colors.white,
      accentColor: Color(0xFFFD6BA2),
      description: "Light purple theme with wave pattern",
      backgroundImage: "assets/Theme 3.png",
    ),
    ThemeOption(
      name: "Soft Yellow",
      backgroundColor: Color(0xFFFFFBE6),
      cardColor: Colors.white,
      accentColor: Color(0xFFFD6BA2),
      description: "Light yellow theme",
      backgroundImage: "assets/Theme 1.png",
    ),
    ThemeOption(
      name: "Mint Green",
      backgroundColor: Color(0xFFE6FFE9),
      cardColor: Colors.white,
      accentColor: Color(0xFFFD6BA2),
      description: "Light green theme",
      backgroundImage: "assets/Theme 5.png",
    ),
    ThemeOption(
      name: "Sky Blue",
      backgroundColor: Color(0xFFE6F4FF),
      cardColor: Colors.white,
      accentColor: Color(0xFFFD6BA2),
      description: "Plain light blue theme",
      backgroundImage: "assets/Theme 6.png",
    ),
  ];
}

class ThemeOption {
  final String name;
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final String description;
  final String backgroundImage; // Add this field

  const ThemeOption({
    required this.name,
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.description,
    required this.backgroundImage,
  });
}
