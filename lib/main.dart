import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth eklendi
import 'screens/home_screens/home_screen.dart'; // Ana sayfa
import 'screens/community_screens/community_screen.dart'; // Topluluk sayfası
import 'screens/profile_screens/profile_screen.dart'; // Profil sayfası
import 'screens/login_screens/login_screen.dart'; // Giriş ekranı eklendi
import 'firebase_options.dart';
import 'services/auth_service.dart'; // AuthService dahil edildi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
      debugShowCheckedModeBanner: false, // Debug yazısını kaldırmak için

      // Kullanıcının giriş yapıp yapmadığını kontrol et
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges, // Kullanıcı durumunu dinliyoruz
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return const HomePage(); // Kullanıcı giriş yaptıysa HomePage aç
            } else {
              return LoginScreen(); // Kullanıcı giriş yapmadıysa LoginScreen aç
            }
          }
          return const Center(child: CircularProgressIndicator()); // Yüklenme ekranı
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

class SelectedIndex{
  static int index = 0;
  static void changeSelectedIndex(int _selectedIndex){
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
            label: '', // Etiketleri boş bırakıyoruz
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/comment.png', width: SelectedIndex.index == 1 ? 30 : 25),
            label: '', // Etiketleri boş bırakıyoruz
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/user2.png', width: SelectedIndex.index == 2 ? 30 : 25),
            label: '', // Etiketleri boş bırakıyoruz
          ),
        ],
      ),
    );
  }
}