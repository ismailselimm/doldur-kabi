import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screens/home_screen.dart';
import 'screens/community_screens/community_screen.dart';
import 'screens/profile_screens/profile_screen.dart';
import 'screens/login_screens/login_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Splash ekranını 3 saniye açık tutalım
  Future.delayed(Duration(seconds: 3), () {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoldurKabı',
      theme: ThemeData(
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return const HomePage();
            } else {
              return LoginScreen();
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

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
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

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
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/zoology.png', width: SelectedIndex.index == 0 ? 30 : 25),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/comment.png', width: SelectedIndex.index == 1 ? 30 : 25),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/user2.png', width: SelectedIndex.index == 2 ? 30 : 25),
            label: '',
          ),
        ],
      ),
    );
  }
}
