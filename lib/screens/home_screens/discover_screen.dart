import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🧭 Sayfa importları
import 'package:doldur_kabi/screens/home_screens/home_screen.dart';
import 'package:doldur_kabi/screens/community_screens/adopt_pet_screen.dart';
import 'package:doldur_kabi/screens/community_screens/lost_pets_screen.dart';
import 'package:doldur_kabi/screens/home_screens/emergency_report_screen.dart';
import 'package:doldur_kabi/screens/community_screens/community_screen.dart';
import 'package:doldur_kabi/screens/home_screens/nearby_vets_screen.dart';
import 'package:doldur_kabi/screens/home_screens/shelter_list_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FF), // Hafif pembe tonlu arka plan
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "DoldurKabında neler yapabilirsin?",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                context,
                imagePath: 'assets/images/mamakabihayvanevi.png',
                title: "Mama Kabı & Hayvan Evi",
                isLeft: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                ),
              ),
              _buildFeatureItem(
                context,
                imagePath: 'assets/images/sahiplendirme.png',
                title: "Hayvan Sahiplendirme",
                isLeft: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdoptionScreen()),
                ),
              ),
              _buildFeatureItem(
                context,
                imagePath: 'assets/images/kayip.png',
                title: "Kayıp Hayvanlar",
                isLeft: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LostPetsScreen()),
                ),
              ),
              _buildFeatureItem(
                context,
                imagePath: 'assets/images/acil.png',
                title: "Acil Durum Bildir",
                isLeft: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmergencyReportScreen()),
                ),
              ),
              _buildFeatureItem(
                context,
                imagePath: 'assets/images/topluluk.png',
                title: "Topluluğa Katıl & Gönderi Paylaş",
                isLeft: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CommunityScreen()),
                ),
              ),
              _buildFeatureItem(
                context,
                imagePath: 'assets/images/vet.png',
                title: "Gönüllü Veteriner Desteği Al",
                isLeft: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NearbyVetsScreen()),
                ),
              ),
              _buildFeatureItem(
                context,
                imagePath: 'assets/images/barinak.png',
                title: "Barınaklar",
                isLeft: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShelterListScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, {
        required String imagePath,
        required String title,
        required bool isLeft,
        required VoidCallback onTap,
      }) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        imagePath,
        width: 140,
        height: 90,
        fit: BoxFit.cover,
      ),
    );

    final text = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: isLeft ? [image, text] : [text, image],
        ),
      ),
    );
  }
}
