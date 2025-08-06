import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/admin_screens/admin_ad_control_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/admin_feedpoint_control_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/admin_post_control_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int toplamKullanici = 0;
  int toplamGonderi = 0;
  int toplamMama = 0;
  int toplamNokta = 0;
  int toplamEv = 0;
  int toplamIlan = 0;
  int toplamVeteriner = 0;



  String aktifKullanici = '-';
  String mamaCanavari = '-';

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final postsSnapshot = await FirebaseFirestore.instance.collection('posts').get();
    final feedPointsSnapshot = await FirebaseFirestore.instance.collection('feedPoints').get();
    final housesSnapshot = await FirebaseFirestore.instance.collection('animalHouses').get();
    final adoptionSnapshot = await FirebaseFirestore.instance.collection('adoption_posts').get();
    final lostPetsSnapshot = await FirebaseFirestore.instance.collection('lost_pets').get();

    int enYuksekPuan = 0;
    int enCokMama = 0;
    String enYuksekPuanIsim = '-';
    String enCokMamaIsim = '-';
    int ilanSayisi = adoptionSnapshot.size + lostPetsSnapshot.size;


    for (var user in usersSnapshot.docs) {
      final data = user.data();
      final puan = (data['points'] as num?)?.toInt() ?? 0;
      final mama = (data['mamaDoldurmaSayisi'] as num?)?.toInt() ?? 0;
      final ad = data['firstName'] ?? '';
      final soyad = data['lastName'] ?? '';
      final isim = "$ad $soyad";
      final String imageUrl = data['imageUrl'] ?? '';


      if (puan > enYuksekPuan) {
        enYuksekPuan = puan;
        enYuksekPuanIsim = isim;
      }

      if (mama > enCokMama) {
        enCokMama = mama;
        enCokMamaIsim = isim;
      }
    }

    final vetSnapshot = await FirebaseFirestore.instance
        .collection('vetApplications')
        .where('status', isEqualTo: 'approved')
        .get();


    toplamMama = usersSnapshot.docs.fold(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final mamaField = data.containsKey('mamaDoldurmaSayisi') ? data['mamaDoldurmaSayisi'] : 0;
      final sayi = (mamaField is int) ? mamaField : (mamaField as num?)?.toInt() ?? 0;
      return sum + sayi;
    });


    setState(() {
      this.toplamKullanici = usersSnapshot.size;
      this.toplamGonderi = postsSnapshot.size;
      this.toplamNokta = feedPointsSnapshot.size;
      this.toplamEv = housesSnapshot.size;
      this.toplamMama = toplamMama;
      this.aktifKullanici = enYuksekPuanIsim;
      this.mamaCanavari = enCokMamaIsim;
      this.toplamIlan = ilanSayisi;
      this.toplamVeteriner = vetSnapshot.size;
    });
  }


  Widget _buildStat(String label, String value, {IconData? icon, VoidCallback? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: icon != null ? Icon(icon, color: const Color(0xFF9346A1)) : null,
        title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: GoogleFonts.poppins(fontSize: 16)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Raporlar',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildStat(
              'Toplam Kullanıcı',
              '$toplamKullanici',
              icon: FontAwesomeIcons.userGroup,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                );
              },
            ),
            _buildStat(
              'Toplam Gönderi',
              '$toplamGonderi',
              icon: FontAwesomeIcons.paperPlane,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPostControlScreen()),
                );
              },
            ),
            _buildStat(
              'Toplam İlan',
              '$toplamIlan',
              icon: FontAwesomeIcons.bullhorn,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminAdControlScreen()),
                );
              },
            ),
            _buildStat('Toplam Mama Doldurma', '$toplamMama', icon: FontAwesomeIcons.bowlFood),
            _buildStat('Toplam Besleme Noktası',
                '$toplamNokta',
                icon: FontAwesomeIcons.mapLocationDot,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminFeedPointControlScreen()),
                );
              },
            ),
            _buildStat('Toplam Hayvan Evi', '$toplamEv', icon: FontAwesomeIcons.houseChimney),
            _buildStat(
              'Toplam Veteriner',
              '$toplamVeteriner',
              icon: FontAwesomeIcons.userDoctor,
            ),


            const SizedBox(height: 20),

            _buildStat('En Aktif Kullanıcı (Puan)', aktifKullanici, icon: FontAwesomeIcons.star),
            _buildStat('En Çok Mama Dolduran', mamaCanavari, icon: FontAwesomeIcons.drumstickBite),
          ],
        ),
      ),
    );
  }
}
