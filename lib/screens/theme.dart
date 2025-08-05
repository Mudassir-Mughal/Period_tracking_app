import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  int currentPage = 0;
  final Color primaryPink = const Color(0xFFFF4F8B);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themes = ThemeProvider.themeOptions;
    final selectedTheme = themeProvider.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.8;

    // Change: Use PageView for snapping effect!
    final PageController pageController = PageController(
      initialPage: themes.indexWhere((t) => t.name == selectedTheme.name),
      viewportFraction: cardWidth / screenWidth,
    );

    return Scaffold(
      backgroundColor: selectedTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Themes",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: themes.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = theme.name == selectedTheme.name;

                return GestureDetector(
                  onTap: () async {
                    await themeProvider.setTheme(theme);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Container(
                    width: cardWidth,
                    margin: EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? theme.accentColor
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            theme.backgroundImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Selected Indicator
                        if (isSelected)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: theme.accentColor,
                                size: 30,
                              ),
                            ),
                          ),
                        // Theme Name and Circle
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            margin: EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.accentColor.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Today",
                                          style: TextStyle(
                                            color: theme.accentColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "Ovulation Day",
                                          style: TextStyle(
                                            color: theme.accentColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
                );
              },
            ),
          ),
          // Apply Button
          Padding(
            padding: EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () async {
                await themeProvider.setTheme(themes[currentPage]);
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Theme applied successfully!'),
                    backgroundColor: themes[currentPage].accentColor,
                  ),
                );

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
    backgroundColor: primaryPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 110 ,vertical: 10),

              ),
              child: Text(
                "Apply",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}