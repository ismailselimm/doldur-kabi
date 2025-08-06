import 'package:doldur_kabi/screens/community_screens/adopt_pet_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doldur_kabi/screens/home_screens/main_home_page.dart';
import 'package:doldur_kabi/screens/home_screens/shelter_list_screen.dart';
import 'package:doldur_kabi/screens/home_screens/nearby_vets_screen.dart';
import 'package:doldur_kabi/screens/home_screens/emergency_report_screen.dart';
import '../community_screens/community_screen.dart';
import '../community_screens/lost_pets_screen.dart';
import '../home_screens/main_home_page.dart' show SelectedIndex;

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  List<Map<String, dynamic>> introItems = [
    {
      "title": "Mama Kabı & Hayvan Evi",
      "image": "assets/images/mamakabihayvanevi.png",
      "index": 0,
    },
    {
      "title": "Hayvan Sahiplendirme",
      "image": "assets/images/sahiplendirme.png",
      "target": "adoption",
    },
    {
      "title": "Topluluk Sayfası",
      "image": "assets/images/topluluk.png",
      "target": "community",
    },
    {
      "title": "Kayıp İlanları",
      "image": "assets/images/kayip.png",
      "target": "lost",
    },
    {
      "title": "Barınaklar",
      "image": "assets/images/barinak.png",
      "target": "shelters",
    },
    {
      "title": "Veterinerler",
      "image": "assets/images/vet.png",
      "target": "vets",
    },
    {
      "title": "Acil Durum",
      "image": "assets/images/acil.png",
      "target": "emergency",
    },
  ];

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FF),
      extendBody: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          itemCount: introItems.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) {
              return FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30, bottom: 20), // 🔥 daha aşağıdan başlasın
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // ortalama
                      children: [
                        Text(
                          "DoldurKabı'na\nHoş Geldin!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 30, // 🔥 daha büyük
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF9346A1),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Uygulamayı kullanmaya başlamadan önce aşağıdaki alanlardan birini seçerek senin için en uygun özelliğe hızlıca geçiş yapabilirsin.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16.2,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (i == introItems.length + 1) {
              return _buildExploreButton(context);
            }

            final item = introItems[i - 1];
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 400 + i * 100),
              tween: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero),
              builder: (context, Offset offset, child) {
                return Transform.translate(
                  offset: offset * 50,
                  child: Opacity(
                    opacity: 1 - offset.dy,
                    child: child,
                  ),
                );
              },
              child: _buildIntroCard(
                context,
                title: item['title'],
                imagePath: item['image'],
                index: item['index'],
                target: item['target'],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExploreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: GestureDetector(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('introShown', true);
            SelectedIndex.changeSelectedIndex(0);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6, // yanlardan daraltıldı
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9346A1), Color(0xFFD16BA5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "Keşfetmeye Başla",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(
      BuildContext context, {
        required String title,
        required String imagePath,
        int? index,
        String? target,
      }) {
    return GestureDetector(
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('introShown', true);

          if (target == "shelters") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShelterListScreen()));
          } else if (target == "vets") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NearbyVetsScreen()));
          } else if (target == "emergency") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyReportScreen()));
          } else if (target == "adoption") {
            SelectedIndex.changeSelectedIndex(1); // Sahiplendirme
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (target == "community") {
            SelectedIndex.changeSelectedIndex(2); // Topluluk
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (target == "lost") {
            SelectedIndex.changeSelectedIndex(3); // Kayıp
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else {
            SelectedIndex.changeSelectedIndex(0);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
          }
        },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black87,
                      offset: Offset(1.5, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
