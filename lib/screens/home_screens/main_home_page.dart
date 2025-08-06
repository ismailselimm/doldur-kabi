import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doldur_kabi/screens/home_screens/home_screen.dart';
import 'package:doldur_kabi/screens/community_screens/adopt_pet_screen.dart';
import 'package:doldur_kabi/screens/community_screens/community_screen.dart';
import 'package:doldur_kabi/screens/community_screens/lost_pets_screen.dart';
import 'package:doldur_kabi/screens/profile_screens/profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class SelectedIndex {
  static int index = 0;
  static void changeSelectedIndex(int _selectedIndex) {
    index = _selectedIndex;
  }
}

class _HomePageState extends State<HomePage> {
  void _onItemTapped(int index) {
    setState(() {
      SelectedIndex.changeSelectedIndex(index);
    });
  }

  final List<Widget> _screens = [
    HomeScreen(),
    AdoptionScreen(),
    CommunityScreen(),
    LostPetsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Giriş yapılmamışsa sadece ProfileScreen'e girmeyi engelle
    if (FirebaseAuth.instance.currentUser == null && SelectedIndex.index == 4) {
      SelectedIndex.changeSelectedIndex(0); // sadece profil ekranına geçmeye çalışıyorsa
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[SelectedIndex.index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: SelectedIndex.index,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/location.png', width: SelectedIndex.index == 0 ? 27 : 20),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/adopt.png', width: SelectedIndex.index == 1 ? 30 : 20),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/people.png', width: SelectedIndex.index == 2 ? 35 : 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/zoology.png', width: SelectedIndex.index == 3 ? 30 : 20),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/user2.png', width: SelectedIndex.index == 4 ? 27 : 20),
            label: '',
          ),
        ],
      ),
    );
  }
}
