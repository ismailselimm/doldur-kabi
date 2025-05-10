import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

class ShelterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> shelter;

  const ShelterDetailScreen({super.key, required this.shelter});

  @override
  State<ShelterDetailScreen> createState() => _ShelterDetailScreenState();
}

class _ShelterDetailScreenState extends State<ShelterDetailScreen> {
  late final PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  final List<Map<String, String>> samplePets = List.generate(9, (index) {
    return {
      'name': ['Pamuk', 'Zeytin', 'Boncuk', 'Tarçın', 'Maya', 'Leo', 'Fıstık', 'Karamel', 'Zuzu'][index],
      'age': (1 + index % 4).toString(),
      'breed': index % 2 == 0 ? 'Van Kedisi' : 'Golden Retriever',
      'type': index % 2 == 0 ? 'kedi.jpeg' : 'kopek.jpg',
    };
  });

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _currentPage = ((_currentPage + 1) % widget.shelter['images'].length).toInt();
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelter = widget.shelter;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          shelter['name'],
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 📸 Banner
            SizedBox(
              height: 240,
              child: PageView.builder(
                controller: _pageController,
                itemCount: shelter['images'].length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _showImageGallery(context, shelter['images'], index),
                  child: Hero(
                    tag: 'image_$index',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: Image.asset(
                        shelter['images'][index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),


            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDFBFF), Color(0xFFF1EAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shelter['description'],
                    style: GoogleFonts.openSans(
                      fontSize: 15.5,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _customInfoRow(FontAwesomeIcons.locationDot, shelter['address']),
                  _customInfoRow(FontAwesomeIcons.paw, 'Hayvan Sayısı: ${shelter['animalCount']}'),
                  _customInfoRow(FontAwesomeIcons.calendar, 'Kuruluş: ${shelter['founded']}'),
                  _customInfoRow(FontAwesomeIcons.user, 'Sorumlu: ${shelter['manager']}'),
                  _customInfoRow(FontAwesomeIcons.phone, 'Telefon: ${shelter['phone']}'),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(
              "Sahiplendirme İlanları",
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 🐾 Sahiplendirme ilanları
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: samplePets.map((pet) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 52) / 2,
                  child: _buildPetCard(pet),
                );
              }).toList(),
            ),


            // 📄 İçerik

          ],
        ),
      ),
    );

  }

  Widget _buildPetCard(Map<String, String> pet) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF9F6FC),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                _showImageGallery(context, ['assets/images/${pet['type']}'], 0);
              },
              child: Hero(
                tag: 'pet_${pet['name']}', // benzersiz olmalı!
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/${pet['type']}',
                    height: 175,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pet['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('Yaş: ${pet['age']}', style: const TextStyle(fontSize: 12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Cins: ${pet['breed']}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Sahiplenme aksiyonu
              },
              icon: const FaIcon(FontAwesomeIcons.paw, size: 14, color: Colors.white),
              label: const Text(
                'Sahiplen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Daha doygun yeşil
                shadowColor: Colors.greenAccent.withOpacity(0.5),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF9346A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FaIcon(icon, color: const Color(0xFF9346A1), size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3.5), // 🔥 Bu satır hizalamayı düzeltir
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageGallery(BuildContext context, List<dynamic> images, int initialIndex) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Gallery",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return _ImageGalleryDialog(images: images, initialIndex: initialIndex);
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }


}

class _ImageGalleryDialog extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const _ImageGalleryDialog({required this.images, required this.initialIndex});

  @override
  State<_ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<_ImageGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🌫️ Blur arkaplan
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),

        Center(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return Hero(
                tag: 'image_$index',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Image.asset(
                    widget.images[index], // ✅ doğru kaynak bu
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          )
        ),

        // ❌ Çarpı butonu
        Positioned(
          top: 120,
          right: 20,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}
