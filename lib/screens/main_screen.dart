import 'package:flutter/material.dart';
import 'home_page.dart';
import '../screens/profile_page.dart';

import 'foodLog_page.dart';
import 'foodheader.dart';

import 'history_page.dart';
import 'coach_page.dart';

import '../services/firestore_service.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? profilePicUrl;
  
  void _setTab(int i) => setState(() => _currentIndex = i);



  final List<String> _titles = [
    'dotted.',
    'Food Log',
    'Add',
    'History',
    'Coach',
  ];

  @override
  void initState() {
    super.initState();
    fetchProfilePicture();
  }

  Future<void> fetchProfilePicture() async {
    final url = await FirestoreService().fetchProfilePictureUrl();
    setState(() {
      profilePicUrl = url;
    });
  }
    

  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(onTabChange: _setTab),
      FoodLogPage(),
      FoodPages(),
      HistoryPage(),
      CoachPage(),
    ];

    return Scaffold(
      appBar: CustomAppBar(_titles[_currentIndex]),

      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFEAEAEA), // Slightly darker than #F1F1F1
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 90, 132, 123),
        unselectedItemColor: const Color.fromARGB(179, 135, 135, 135),
        onTap: (index) {
          setState(() => _currentIndex = index);
        },

        selectedIconTheme: const IconThemeData(size: 25),
        unselectedIconTheme: const IconThemeData(size: 22),

        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Coach',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget CustomAppBar(String pageName)  {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
          fetchProfilePicture();
        },
        child: Container(
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            radius: 17,
            backgroundImage: profilePicUrl != null && profilePicUrl!.isNotEmpty
                ? NetworkImage(profilePicUrl!)
                : const AssetImage('images/profile-icon-placeholder.png')
                    as ImageProvider,
          ),
        ),
      ),
      title: Text(
        pageName,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}
