import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Example list of animal asset paths (add yours here)
const animalAssets = [
  'assets/animal1.png',
  'assets/animal2.png',
  'assets/animal3.png',
  'assets/animal4.png',
  'assets/animal5.png',
  'assets/animal6.png',
  'assets/animal7.png',
  'assets/animal8.png',
  'assets/animal9.png',
  'assets/animal10.png',
  'assets/animal11.png',
  'assets/animal12.png',
  'assets/animal13.png',
  'assets/animal14.png',
  'assets/animal15.png',
  'assets/animal16.png',
  'assets/animal17.png',
  'assets/animal18.png',
  'assets/animal19.png',
  'assets/animal20.png',
  'assets/animal21.png',

];

class EditCatScreen extends StatefulWidget {
  final String selectedAnimalAsset; // currently selected animal asset

  const EditCatScreen({Key? key, required this.selectedAnimalAsset}) : super(key: key);

  @override
  State<EditCatScreen> createState() => _EditCatScreenState();
}

class _EditCatScreenState extends State<EditCatScreen> {
  late String currentSelected;

  @override
  void initState() {
    super.initState();
    currentSelected = widget.selectedAnimalAsset;
  }

  void _onAnimalTap(String asset) {
    setState(() {
      currentSelected = asset;
    });
    // After selecting, pop and return the selected animal asset path
    Navigator.pop(context, currentSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Your Pet',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: animalAssets.length ,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final asset = animalAssets[index];
            final isSelected = asset == currentSelected;
            return GestureDetector(
              onTap: () => _onAnimalTap(asset),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: Colors.pink, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}