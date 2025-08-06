import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/profile_screens/help_page.dart';
import 'package:doldur_kabi/screens/profile_screens/invite_friends_page.dart';
import 'package:doldur_kabi/screens/login_screens/login_screen.dart';
import 'package:doldur_kabi/screens/profile_screens/supporters_screen.dart';
import 'package:doldur_kabi/screens/profile_screens/true_information.dart';
import 'package:doldur_kabi/screens/profile_screens/update_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../community_screens/user_profile_screen.dart';
import 'belediyelerimiz_screen.dart';
import 'contact_us_page.dart';
import 'package:doldur_kabi/screens/profile_screens/messages_screen.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Yeni ikonlar için
import 'legal_info_page.dart';
import 'my_feeds_and_houses_screen.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
 // int doldurKabiPuan = 900;
  int beslemeNoktasiSayisi = 0;  // 🔥 Başlangıçta 0 olsun
  int hayvanEviSayisi = 0;  // 🔥 Başlangıçta 0 olsun
  int mamaDoldurmaSayisi = 0;  // 🔥 Yeni değişken
  int gonderiSayisi = 0;


  @override

  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    } else {
      // 🔥 Verinin gerçekten yüklenmesini garanti etmek için gecikme ekliyoruz.
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _getUserContributions();
        }
      });
    }
  }


  /// **🔥 Kullanıcının katkılarını direkt `users` koleksiyonundan çek**
  Future<void> _getUserContributions() async {
    if (user == null) return;

    String userId = user!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // mama, besleme, ev sayıları
      final userDoc = await firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // gönderi sayısını koleksiyonlardan hesapla
      final posts = await firestore.collection('posts').where('userId', isEqualTo: userId).get();
      final adoptions = await firestore.collection('adoption_posts').where('ownerId', isEqualTo: userId).get();
      final lostPets = await firestore.collection('lost_pets').where('userId', isEqualTo: userId).get();
      final totalGonderi = posts.size + adoptions.size + lostPets.size;

      setState(() {
        mamaDoldurmaSayisi = userData['mamaDoldurmaSayisi'] ?? 0;
        beslemeNoktasiSayisi = userData['beslemeNoktasiSayisi'] ?? 0;
        hayvanEviSayisi = userData['hayvanEviSayisi'] ?? 0;
        gonderiSayisi = totalGonderi; // 🔥 Doğru sayı burada!
      });

    } catch (e) {
      print("❌ Kullanıcı katkılarını çekerken hata oluştu: $e");
    }
  }


  Future<void> _fetchUpdatedUserData() async {
    if (user == null) return;

    try {
      await user!.reload(); // 🔥 Firebase Authentication verisini yenile
      user = FirebaseAuth.instance.currentUser;

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          user = FirebaseAuth.instance.currentUser;
        });
      }

      print("✅ Kullanıcı bilgileri güncellendi: ${user!.photoURL}");
    } catch (e) {
      print("❌ HATA: Kullanıcı verisi güncellenemedi: $e");
    }
  }


  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Köşeleri yuvarlak
          title: Text(
            "Çıkış Yap",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
          ),
          content: Text(
            "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // **Hayır** seçilirse sadece kapat
              },
              child: Text("Hayır", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen())); // **Evet** seçilirse çıkış yap
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: Text("Evet", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
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
          automaticallyImplyLeading: false, // 🔥 Geri butonunu tamamen kaldır!
          centerTitle: true,
          elevation: 0,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Stack(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (_, __, ___) => FullScreenImage(imageUrl: user!.photoURL!),
                            ),
                          );
                        }
                      },
                      child: Hero(
                        tag: 'profileImage',
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.25),
                                blurRadius: 16,
                                spreadRadius: 3,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                              ? FutureBuilder(
                            future: precacheImage(NetworkImage(user!.photoURL!), context),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                return CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(user!.photoURL!),
                                );
                              } else {
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[300],
                                  ),
                                );
                              }
                            },
                          )
                              : const CircleAvatar(
                            radius: 60,
                            backgroundImage: AssetImage('assets/images/avatar1.png'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 🔥 İsim + info ikonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(
                                  userId: user!.uid,
                                  userEmail: user!.email ?? '',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            user?.displayName ?? 'Kullanıcı Adı',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text("Bilgilendirme"),
                                content: Text(
                                  "DoldurKabı profilinizi görmek için isminize dokunun.\n\nBu sayfa diğer kullanıcıların sizi nasıl gördüğünü gösterir.",
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text("Kapat"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const FaIcon(
                            FontAwesomeIcons.infoCircle,
                            size: 20,
                            color: Colors.black87,
                          ),

                        ),
                      ],
                    ),


                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'E-posta mevcut değil',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),

                // Ayarlar ikonu sağ üstte ve dışarı taşmıyor
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const FaIcon(FontAwesomeIcons.alignLeft, color: Colors.black87, size: 20),
                    onPressed: () async {
                      bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
                      );
                      if (updated == true) _fetchUpdatedUserData();
                    },
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildOptionTile(
                  icon: FontAwesomeIcons.handshake, // 🤝 Destekçilerimiz
                  title: 'Destekçilerimiz',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SupportersScreen()),
                    );
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.buildingColumns,
                  title: 'Belediyelerimiz',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  MunicipalitiesScreen()),
                    );
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.envelope, // ✉️ Mesajlarım
                  title: 'Mesajlarım',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesScreen()));
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.boxOpen, // 📦 güzel bir katkı teması
                  title: 'Katkılarım',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyFeedsAndHousesScreen()),
                    );
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.bullhorn, // 📢 Paylaşımlarım
                  title: 'Paylaşımlarım',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => IlanlarimScreen()));
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.lightbulb, // 💡 Doğru Bilinen Yanlışlar
                  title: 'Doğru Bilinen Yanlışlar',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MythsPage()));
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.circleQuestion, // ❓ Yardım
                  title: 'Yardım',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpPage()));
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.commentDots, // 📞 Bize Ulaşın
                  title: 'Bize Ulaşın',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsPage()));
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.scaleBalanced,
                  title: 'Yasal Bilgiler',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalInfoPage()));
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.shareFromSquare, // 🔗 Paylaş
                  title: "DoldurKabı'yı Paylaş",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteFriendsPage()));
                  },
                ),
                _buildOptionTile(
                  icon: FontAwesomeIcons.doorOpen, // 🚪 Çıkış
                  title: 'Çıkış Yap',
                  onTap: () {
                    _showLogoutConfirmation();
                  },
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "Uygulama Versiyonu : 1.0.0",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E), // Koyu arka plan (iOS stili siyah)
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        // 🔗 Instagram'a yönlendirme
                        final url = Uri.parse('https://www.instagram.com/doldurkabi?igsh=dzFkOXcyMDhpNm1i');
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976), Color(0xFF962FBF), Color(0xFF4F5BD5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                FontAwesomeIcons.instagram,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instagram’da Takip Et',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@doldurkabi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ),

        ],
      ),
    );
  }


  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.deepPurple.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white60,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black87), // 🟣 Mor ton
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
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