import 'dart:async';
import 'package:doldur_kabi/screens/home_screens/shelter_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ShelterListScreen extends StatelessWidget {
  const ShelterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shelters = [
      {
        'images': [
          'assets/images/ornbarinak1.png',
          'assets/images/ornbarinak2.png',
        ],
        'name': 'Sarıyer Belediyesi Bakımevi',
        'description':
        'Doğa ile iç içe, modern donanımlı bu merkez; tedavi, barınma ve sahiplendirme hizmetleri sunar. Gönüllülerin aktif desteği ile sürdürülen bir modeldir.',
        'address': 'Maden Mah. Hayvansever Sk. No:5 Sarıyer/İstanbul',
        'animalCount': 18,
        'founded': 2014,
        'manager': 'Dr. Ayşe Karaca',
        'phone': '0212 444 17 22',
        'municipality': 'Sarıyer Belediyesi',
        'badge': 'assets/images/sariyerbelediyesi.png', // 💠 Yeni: Belediye logosu!
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        title: Text(
          'Barınaklar',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: shelters.length,
        itemBuilder: (context, index) => ShelterCard(shelter: shelters[index]),
      ),
    );
  }
}

class ShelterCard extends StatefulWidget {
  final Map<String, dynamic> shelter;

  const ShelterCard({super.key, required this.shelter});

  @override
  State<ShelterCard> createState() => _ShelterCardState();
}

class _ShelterCardState extends State<ShelterCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final List images = widget.shelter['images'] as List;
      final int totalPages = images.length;

      _currentPage = (_currentPage + 1) % totalPages;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });

  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelter = widget.shelter;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: shelter['images'].length,
                    itemBuilder: (context, index) => Image.asset(
                      shelter['images'][index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              // 🟣 Üstte Belediye Rozeti ve Etiket
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(shelter['badge']),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shelter['municipality'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 🔻 Alt kısmın üstüne bindirilmiş başlık şeridi
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    shelter['name'],
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          _buildInfoSection(shelter),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> shelter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shelter['description'],
            style: GoogleFonts.openSans(fontSize: 14.5, height: 1.6),
          ),
          const SizedBox(height: 10),
          _infoRow(FontAwesomeIcons.dog, 'Hayvan sayısı: ${shelter['animalCount']}'),
          _infoRow(FontAwesomeIcons.userTie, 'Sorumlu: ${shelter['manager']}'),
          _infoRow(FontAwesomeIcons.calendarDays, 'Kuruluş yılı: ${shelter['founded']}'),
          _infoRow(FontAwesomeIcons.phoneVolume, 'Tel: ${shelter['phone']}'),

          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Barınak ile İlgili İşlemler",
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShelterDetailScreen(shelter: shelter),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE7F4),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(FontAwesomeIcons.infoCircle, size: 26, color: Color(0xFF7C4DFF)),
                              const SizedBox(height: 8),
                              Text("Detaylar", style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final Uri googleMapsUrl = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(shelter['address'])}',
                          );
                          if (await canLaunchUrl(googleMapsUrl)) {
                            await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F6F1),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(FontAwesomeIcons.mapMarkedAlt, size: 26, color: Colors.teal),
                              const SizedBox(height: 8),
                              Text("Yol Tarifi", style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF9346A1),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
