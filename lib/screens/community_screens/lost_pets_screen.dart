import 'dart:ui';
import 'package:doldur_kabi/screens/community_screens/add_lost_pet_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'adopt_pet_screen.dart';

class LostPetsScreen extends StatefulWidget {
  @override
  _LostPetsScreenState createState() => _LostPetsScreenState();
}

class _LostPetsScreenState extends State<LostPetsScreen> {
  String selectedCategory = "Tümü";

  final List<Map<String, dynamic>> lostPets = [
    {
      "petName": "Minnoş",
      "location": "İstanbul, Kadıköy",
      "type": "kedi",
      "phoneNumber": "+905555555555",
    },
    {
      "petName": "Karabaş",
      "location": "Ankara, Çankaya",
      "type": "köpek",
      "phoneNumber": "+905444444444",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kayıp Hayvanlar',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white, size: 33), // Burada size parametresini ekledim
            tooltip: 'Kayıp Hayvan İlan Ver',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddLostPetScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryButton("Tümü"),
                    _buildStackedCategoryButton("Kedi", "İlanları"),
                    _buildStackedCategoryButton("Köpek", "İlanları"),
                  ],
                ),
                SizedBox(height: 16), // Boşluk eklendi
                Text(
                  "Sonuçlar en yakından en uzağa sıralanmıştır.",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 1), // 18'di, 4 yaptık
              children: lostPets
                  .where((pet) {
                if (selectedCategory == "Tümü") return true;
                if (selectedCategory == "Kedi İlanları" && pet['type'] == 'kedi') return true;
                if (selectedCategory == "Köpek İlanları" && pet['type'] == 'köpek') return true;
                return false;
              })
                  .map((pet) => _buildLostPetCard(pet))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedCategoryButton(String topText, String bottomText) {
    bool isSelected = selectedCategory.contains(topText);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey, width: 2),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedCategory = "$topText İlanları";
        });
      },
      child: Column(
        children: [
          Text(topText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(bottomText, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    bool isSelected = selectedCategory == category;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey, width: 2),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Text(category, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLostPetCard(Map<String, dynamic> pet) {
    String imagePath = pet['type'] == 'kedi' ? 'assets/images/kayipkedi.jpg' : 'assets/images/kayipkopek.jpeg';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 12),
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                _showImagePopup(context, imagePath);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(imagePath, fit: BoxFit.cover, height: 200, width: 200),
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['petName'] ?? "Bilinmeyen",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "📍 ${pet['location'] ?? 'Bilinmiyor'}",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _makePhoneCall(pet['phoneNumber']);
                    },
                    icon: Icon(Icons.phone, color: Colors.white), // İkonu beyaz yaptım
                    label: Text(
                      "Ara",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Yazıyı beyaz yaptım
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePopup(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(imagePath, width: 500, height: 500, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Arama yapılamıyor")),
      );
    }
  }
}
