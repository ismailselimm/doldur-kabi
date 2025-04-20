import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/profile_screens/help_page.dart';
import 'package:doldur_kabi/screens/profile_screens/invite_friends_page.dart';
import 'package:doldur_kabi/screens/login_screens/login_screen.dart';
import 'package:doldur_kabi/screens/profile_screens/privacy_notice_page.dart';
import 'package:doldur_kabi/screens/profile_screens/privacy_policy_page.dart';
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
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Yeni ikonlar için
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
      print("🔥 Kullanıcı katkıları çekiliyor... UID: $userId");

      // **🔥 Kullanıcı bilgilerini `users` koleksiyonundan al**
      DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print("❌ Kullanıcı Firestore'da bulunamadı!");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        beslemeNoktasiSayisi = userData['beslemeNoktasiSayisi'] ?? 0;
        hayvanEviSayisi = userData['hayvanEviSayisi'] ?? 0;
        gonderiSayisi = userData['gonderiSayisi'] ?? 0;
        mamaDoldurmaSayisi = userData['mamaDoldurmaSayisi'] ?? 0;
      });

      print("✅ Firestore verileri başarıyla çekildi!");
      print("📌 Besleme Noktası: $beslemeNoktasiSayisi");
      print("📌 Hayvan Evi: $hayvanEviSayisi");
      print("📌 Gönderi: $gonderiSayisi");
      print("📌 Mama Doldurma: $mamaDoldurmaSayisi");
    } catch (e) {
      print("❌ Hata: Kullanıcı verileri çekilirken sorun oluştu: $e");
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

  Widget _buildProfileStat(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value, // 🔥 SAYI ÖNCE
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 6), // 🔥 Sayı ile ikon arasına boşluk ekle
              Transform.translate(
                offset: const Offset(0, -1), // 🔥 İKONU BİRAZ YUKARI AL
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title, // 🔥 AÇIKLAMA
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
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
          automaticallyImplyLeading: false, // 🔥 Geri butonunu tamamen kaldır!
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
                            child: ClipOval(
                              child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                                  ? Image.network(
                                user!.photoURL!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const CircularProgressIndicator(); // Yüklenirken gösterilecek
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset('assets/images/avatar1.png'); // Hata olursa varsayılan resim
                                },
                              )
                                  : Image.asset('assets/images/avatar1.png'), // Varsayılan resim
                            ),
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
                        icon: const FaIcon(FontAwesomeIcons.gear, color: Colors.grey, size: 20,), // Ayarlar
                        onPressed: () async {
                          bool? updated = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
                          );

                          if (updated == true) {
                            _fetchUpdatedUserData(); // ✅ **Profil güncellendi, Firebase’den yeni veriyi çek**
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300]),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat("Mama Doldurma", "$mamaDoldurmaSayisi", Colors.blueAccent[700]!, FontAwesomeIcons.bowlFood),
                          _buildProfileStat("Besleme Kabı", "$beslemeNoktasiSayisi", Colors.pink, FontAwesomeIcons.paw),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat("Hayvan Evi", "$hayvanEviSayisi", Colors.teal, FontAwesomeIcons.houseChimney),
                          _buildProfileStat("Gönderi Paylaşma", "$gonderiSayisi", Colors.orange, FontAwesomeIcons.paperPlane),
                        ],
                      ),
                    ],
                  ),
               /*   Row(
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
                  ), */
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
                    icon: FontAwesomeIcons.solidMessage, // 🗨️ Mesajlar
                    title: 'Mesajlarım',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesScreen()));
                    }),
                _buildOptionTile(
                  icon: FontAwesomeIcons.bullhorn, // 📢 Duyurular
                  title: 'Paylaşımlarım',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => IlanlarimScreen()),);
                    },),
                _buildOptionTile(
                    icon: FontAwesomeIcons.lightbulb, // 💡 Bilgilendirme
                    title: 'Doğru Bilinen Yanlışlar',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MythsPage()));
                    }),
                _buildOptionTile(
                    icon: FontAwesomeIcons.solidCircleQuestion, // ❓ Yardım
                    title: 'Yardım',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpPage()));
                    }),
                _buildOptionTile(
                    icon: FontAwesomeIcons.phoneVolume, // 📞 İletişim
                    title: 'Bize Ulaşın',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsPage()));
                    }),
                _buildOptionTile(
                    icon: FontAwesomeIcons.userShield, // 🛡️ Gizlilik
                    title: 'Gizlilik Politikası',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
                    }),
                _buildOptionTile(
                    icon: FontAwesomeIcons.fileContract, // 📄 Şartlar
                    title: 'Kullanım Şartları',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()));
                    }),
                _buildOptionTile(
                    icon: FontAwesomeIcons.circleInfo, // ℹ️ Aydınlatma Metni
                    title: 'Aydınlatma Metni',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyNoticePage()));
                    }),
                _buildOptionTile(
                    icon: FontAwesomeIcons.shareNodes, // 🔗 Paylaşım
                    title: "DoldurKabı'yı Paylaş",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteFriendsPage()));
                    }),
                _buildOptionTile(
                    icon: FontAwesomeIcons.arrowRightFromBracket, // 🚪 Çıkış
                    title: 'Çıkış Yap',
                    onTap: () {
                      _showLogoutConfirmation();
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
        leading: Icon(icon,size: 22, color: Colors.black87),
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