import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/profile_screens/help_page.dart';
import 'package:doldur_kabi/screens/profile_screens/invite_friends_page.dart';
import 'package:doldur_kabi/screens/login_screens/login_screen.dart';
import 'package:doldur_kabi/screens/profile_screens/privacy_notice_page.dart';
import 'package:doldur_kabi/screens/profile_screens/privacy_policy_page.dart';
import 'package:doldur_kabi/screens/profile_screens/supporters_page.dart';
import 'package:doldur_kabi/screens/profile_screens/terms_page.dart';
import 'package:doldur_kabi/screens/profile_screens/true_information.dart';
import 'package:doldur_kabi/screens/profile_screens/update_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'contact_us_page.dart';
import 'package:doldur_kabi/screens/profile_screens/messages_screen.dart';
import 'dart:ui';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  int doldurKabiPuan = 900;
  int beslemeNoktasiSayisi = 0;  // 🔥 Başlangıçta 0 olsun
  int hayvanEviSayisi = 0;  // 🔥 Başlangıçta 0 olsun
  int mamaDoldurmaSayisi = 0;  // 🔥 Yeni değişken
  int gonderiSayisi = 0;




  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    // Giriş yapılmamışsa LoginScreen'e yönlendirme
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    } else {
      _getUserContributions(); // 🔥 Firebase’den kaç tane eklediğini al
    }
  }


  Future<void> _getUserContributions() async {
    if (user == null) return;

    String userId = user!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Kullanıcının eklediği besleme noktalarını say
      QuerySnapshot feedPointsSnapshot = await firestore
          .collection('feedPoints')
          .where('addedBy', isEqualTo: userId)
          .get();

      // Kullanıcının eklediği hayvan evlerini say
      QuerySnapshot animalHousesSnapshot = await firestore
          .collection('animalHouses')
          .where('addedBy', isEqualTo: userId)
          .get();

      // Kullanıcının mama doldurma sayısını al
      DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();

      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('addedBy', isEqualTo: userId)
          .get();

      setState(() {
        gonderiSayisi = postsSnapshot.docs.length;
      });

      print("🔥 Gönderi Sayısı: $gonderiSayisi");

      setState(() {
        beslemeNoktasiSayisi = feedPointsSnapshot.docs.length;
        hayvanEviSayisi = animalHousesSnapshot.docs.length;
        mamaDoldurmaSayisi = userDoc.exists && userDoc['mamaDoldurmaSayisi'] != null
            ? userDoc['mamaDoldurmaSayisi']
            : 0; // Eğer veri yoksa 0 olarak ayarla
      });

      print("🔥 Firebase'den çekildi: Besleme Noktası: $beslemeNoktasiSayisi, Hayvan Evi: $hayvanEviSayisi, Mama Doldurma: $mamaDoldurmaSayisi");

    } catch (e) {
      print("❌ Hata: Firebase verileri çekilemedi -> $e");
    }
  }

  Future<void> _fetchUserContributions() async {
    String userID = user!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Kullanıcının eklediği besleme noktası sayısını getir
    QuerySnapshot feedPointsSnapshot = await firestore
        .collection('feedPoints')
        .where('addedBy', isEqualTo: userID)
        .get();

    // Kullanıcının eklediği hayvan evi sayısını getir
    QuerySnapshot animalHousesSnapshot = await firestore
        .collection('animalHouses')
        .where('addedBy', isEqualTo: userID)
        .get();

    setState(() {
      beslemeNoktasiSayisi = feedPointsSnapshot.docs.length;
      hayvanEviSayisi = animalHousesSnapshot.docs.length;
    });
  }

  Widget _buildProfileStat(String title, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // Kullanıcı giriş yapmadıysa boş bir widget döndür
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF9346A1),
          title: Text(
            'Profil',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false, // 🔥 Sayfa yarı şeffaf olacak
                                pageBuilder: (_, __, ___) => FullScreenImage(imageUrl: user!.photoURL!),
                              ),
                            );
                          }
                        },
                        child: Hero(
                          tag: 'profileImage',
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: user?.photoURL != null && user!.photoURL!.isNotEmpty
                                ? CachedNetworkImageProvider(user!.photoURL!) as ImageProvider<Object>
                                : const AssetImage('assets/images/avatar1.png'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Kullanıcı Adı',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'E-posta mevcut değil',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: Colors.grey[600]),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>const UpdateProfilePage()));
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat("Mama Doldurma Sayısı", "$mamaDoldurmaSayisi", Colors.blueAccent[700]!),
                          _buildProfileStat("Besleme Noktası Ekleme", "$beslemeNoktasiSayisi", Colors.pink),
                        ],
                      ),
                      const SizedBox(height: 16), // 🔥 Üst ve alt blok arasında boşluk
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat("Hayvan Evi Ekleme", "$hayvanEviSayisi", Colors.teal),
                          _buildProfileStat("Gönderi Paylaşma", "$gonderiSayisi", Colors.orange),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "DoldurKabı Puanı:  ",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 🔥 Arkaplan ve padding ekledik
                        decoration: BoxDecoration(
                          color: Colors.amber[700], // 🔥 Altın Sarısı Arkaplan
                          borderRadius: BorderRadius.circular(20), // Hafif köşeli görünüm
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 5),
                            Text(
                              "$doldurKabiPuan ",
                              style: GoogleFonts.poppins(
                                fontSize: 18, // Daha büyük font
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Beyaz yazı
                              ),
                            ),
                            Icon(Icons.stars, color: Colors.white, size: 22), // ⭐ Premium Hissi
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildOptionTile(
                    icon: Icons.message_outlined,
                    title: 'Mesajlarım',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesScreen()));
                    }),
                _buildOptionTile(
                    icon: Icons.help_outline,
                    title: 'Yardım',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpPage()));
                    }),
                _buildOptionTile(
                    icon: Icons.contact_phone_outlined,
                    title: 'Bize Ulaşın',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsPage()));
                    }),
                _buildOptionTile(
                    icon: Icons.help_center_outlined,
                    title: 'Doğru Bilinen Yanlışlar',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MythsPage()));
                    }),
                _buildOptionTile(
                    icon: Icons.favorite_border,
                    title: 'Destekçilerimiz',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SupportersScreen()));
                    }),
                _buildOptionTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik Politikası',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
                    }),
                _buildOptionTile(
                    icon: Icons.description_outlined,
                    title: 'Kullanım Şartları',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()));
                    }),
                _buildOptionTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Aydınlatma Metni',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyNoticePage()));
                    }),
                _buildOptionTile(
                    icon: Icons.share,
                    title: "DoldurKabı'yı Paylaş",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteFriendsPage()));
                    }),
                _buildOptionTile(
                    icon: Icons.exit_to_app,
                    title: 'Çıkış Yap',
                    onTap: () async {
                      await AuthService().signOut();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                    }),
          const SizedBox(height: 10),
                Center(
                  child: Text(
                    "Uygulama Versiyonu : 1.0.0",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF9346A1)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
        onTap: onTap,
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // **1️⃣ Arka planı bulanıklaştırma, uygulama görünür kalacak**
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Blur efekti
            child: Container(
              color: Colors.black.withOpacity(0.2), // Hafif karartma efekti
            ),
          ),
        ),

        // **2️⃣ Tam ekran fotoğrafı (DAHA BÜYÜK DAİRE)**
        Center(
          child: Hero(
            tag: 'profileImage',
            child: ClipOval( // 🔥 Fotoğrafı daire yapıyor
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 300, // 📌 Daha büyük daire (300x300 yapıldı)
                height: 300, // 📌 Daha büyük daire
                fit: BoxFit.cover, // Daireye sığdır
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),

        // **3️⃣ Sağ üstte kapatma butonu**
        Positioned(
          top: 70,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}