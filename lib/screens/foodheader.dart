import 'package:flutter/material.dart';

import 'library_food.dart';
import 'library_exercise.dart';

class FoodPages extends StatefulWidget {
  const FoodPages({super.key});

  @override
  State<FoodPages> createState() => _FoodPagesState();
}

class _FoodPagesState extends State<FoodPages> {
  final PageController _pageController = PageController();

  int selectedTabIndex = 0;
  final List<Widget> _tabPages = [
    FoodLibraryPage(),
    ExerciseLibrary()
  ];

  void onTabTap(int index) {
    setState(() {
      selectedTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Changed to white
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent, // Background of the tab bar
              ),

              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              margin: const EdgeInsets.symmetric(horizontal: 0),

              //custom tab bar
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTabButton('Foods', 0),
                  _buildTabButton('Exercises', 1),

                ],
              ),
            ),

            // Display Selected Page
            // Animated PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
                children: _tabPages,
              ),
            ),
          ],
        ),
      ),
    );
  } //BUILD

  Widget _buildTabButton(String label, int index) {
    final isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Color.fromARGB(255, 87, 94, 94) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
