import 'dart:async';
import 'package:doldur_kabi/screens/home_screens/shelter_application_screen.dart';
import 'package:doldur_kabi/screens/home_screens/shelter_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'emergency_report_screen.dart';

class ShelterListScreen extends StatelessWidget {
  const ShelterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shelters = [
      {
        'images': [
          'assets/images/sariyerbelediyesi.png',
          'assets/images/kucukcekmecebel.png',
        ],
        'name': 'Sarıyer Belediyesi',
        'description': 'İstanbul’un kuzeyinde, doğayla iç içe konumlanan modern bir barınaktır. '
            'Sokak hayvanlarına sıcak bir yuva sağlamak amacıyla kurulmuştur. '
            'Gönüllüler ve veterinerler eşliğinde düzenli bakım ve tedavi hizmeti sunulmaktadır. '
            'Sahiplendirme, kısırlaştırma ve rehabilitasyon hizmetleriyle fark yaratmaktadır.',
        'address': 'Maden Mah. Hayvansever Sk. No:5 Sarıyer/İstanbul',
        'animalCount': 18,
        'founded': 2014,
        'manager': 'Dr. Ayşe Karaca',
        'phone': '0212 444 17 22',
      },

    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Barınaklar',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white,size:36),
            tooltip: 'Barınak Başvurusu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShelterApplicationScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
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
    if (widget.shelter['images'].length > 1) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        _currentPage = ((_currentPage + 1) % widget.shelter['images'].length).toInt();
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelter = widget.shelter;

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F6FA), Color(0xFFF1ECF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: shelter['images'].length,
              physics: const BouncingScrollPhysics(), // 🔥 kaydırma hissini sağlar
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.asset(
                  shelter['images'][index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter['name'],
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shelter['description'],
                  style: GoogleFonts.openSans(fontSize: 14.5, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                infoRow(Icons.location_on, shelter['address']),
                infoRow(Icons.pets, 'Barınaktaki hayvan sayısı: ${shelter['animalCount']}'),
                infoRow(Icons.calendar_month, 'Kuruluş yılı: ${shelter['founded']}'),
                infoRow(Icons.person, 'Sorumlu kişi: ${shelter['manager']}'),
                infoRow(Icons.phone, 'Telefon: ${shelter['phone']}'),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.info,
                      label: "İncele",
                      color: const Color(0xFF7C4DFF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShelterDetailScreen(shelter: shelter),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.directions,
                      label: "Yol Tarifi",
                      color: Colors.black87,
                      onTap: () async {
                        final Uri googleMapsUrl = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(shelter['address'])}',
                        );
                        if (await canLaunchUrl(googleMapsUrl)) {
                          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EmergencyReportScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        minimumSize: const Size(72, 60),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Acil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text("Durum", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),



              ],
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }


  Widget infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF9346A1), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
