
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doldur_kabi/screens/community_screens/adoption_post_screen.dart';

class AdoptionScreen extends StatefulWidget {
  @override
  _AdoptionScreenState createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  String _selectedCategory = 'Tümü';
  final List<Map<String, String>> _adoptions = [
    {
      'type': 'Köpek',
      'description': 'Golden Retriever yavru, aşıları tam, sevgi dolu bir yuva arıyor.',
      'image': 'assets/images/kopek.jpg',
      'owner': 'Mehmet Yılmaz'
    },
    {
      'type': 'Kedi',
      'description': 'Sevimli kedi, oyuncu ve insanlara alışkın, sıcak bir yuva arıyor.',
      'image': 'assets/images/kedi.jpeg',
      'owner': 'Ayşe Demir'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hayvan Sahiplen',
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
            icon: Icon(Icons.add, color: Colors.white, size: 33),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdoptionPostScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton('Tümü'),
                const SizedBox(width: 10),
                _buildFilterButton('Kedi'),
                const SizedBox(width: 10),
                _buildFilterButton('Köpek'),
              ],
            ),
            Expanded(
              child: ListView(
                children: _adoptions
                    .where((adopt) => _selectedCategory == 'Tümü' || adopt['type'] == _selectedCategory)
                    .map((adopt) => _buildAdoptionCard(adopt))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedCategory == category ? const Color(0xFF9346A1) : Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(category, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildAdoptionCard(Map<String, String> adopt) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _showImagePopup(context, adopt['image']!);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(adopt['image']!, fit: BoxFit.cover, width: double.infinity, height: 220),
              ),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${adopt['type']} İlanı',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF9346A1)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              adopt['description']!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 5),
            Divider(color: Colors.grey[400]),
            const SizedBox(height: 5),
            Text(
              'İlan Sahibi: ${adopt['owner']}',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9346A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.message, color: Colors.white),
                label: const Text('Mesaj Gönder', style: TextStyle(color: Colors.white)),
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
}
