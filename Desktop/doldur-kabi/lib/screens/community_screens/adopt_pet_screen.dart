import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/community_screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doldur_kabi/screens/community_screens/adoption_post_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../profile_screens/chat_screen.dart';

class AdoptionScreen extends StatefulWidget {
  @override
  _AdoptionScreenState createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  String _selectedCategory = 'Tümü';
  String? _selectedCity = "Tümü"; // 🏙️ Varsayılan olarak "Tümü"
  final List<String> _cityList = [
    "Tümü", "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Amasya", "Ankara", "Antalya", "Artvin", "Aydın",
    "Balıkesir", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı",
    "Çorum", "Denizli", "Diyarbakır", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir", "Gaziantep",
    "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Isparta", "Mersin", "İstanbul", "İzmir", "Kars",
    "Kastamonu", "Kayseri", "Kırklareli", "Kırşehir", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa",
    "Kahramanmaraş", "Mardin", "Muğla", "Muş", "Nevşehir", "Niğde", "Ordu", "Rize", "Sakarya",
    "Samsun", "Siirt", "Sinop", "Sivas", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Şanlıurfa",
    "Uşak", "Van", "Yozgat", "Zonguldak", "Aksaray", "Bayburt", "Karaman", "Kırıkkale", "Batman",
    "Şırnak", "Bartın", "Ardahan", "Iğdır", "Yalova", "Karabük", "Kilis", "Osmaniye", "Düzce"
  ];
  String getCityText() {
    if (_selectedCity == "Tümü") {
      return "Tüm şehirlerdeki ilanlar gösteriliyor";
    } else if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      return "$_selectedCity şehrindeki ilanlar gösteriliyor";
    } else {
      return "Şehir bilgisi bulunamadı";
    }
  }




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
        iconTheme: const IconThemeData(color: Colors.white),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategoriler
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildFilterButton('Tümü')),
                const SizedBox(width: 10),
                Expanded(child: _buildFilterButton('Kedi')),
                const SizedBox(width: 10),
                Expanded(child: _buildFilterButton('Köpek')),
              ],
            ),
            const SizedBox(height: 12),

            // Şehir Seçme Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonFormField<String>(
                value: _selectedCity,
                isExpanded: true,
                menuMaxHeight: 250, // Maksimum yükseklik (5 şehir gösterir)
                icon: Icon(FontAwesomeIcons.caretDown, color: Colors.purple), // FontAwesome ikon eklendi
                decoration: InputDecoration(border: InputBorder.none), // Alt çizgiyi kaldır
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                items: _cityList.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            // Seçilen Şehir Başlığı
            Card(
              elevation: 3,
              color: Colors.purple.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.mapMarkerAlt, color: Colors.purple), // Şehir ikonu eklendi
                    SizedBox(width: 8),
                    Text(
                      "$_selectedCity şehrindeki ilanlar gösteriliyor",
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.purple),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // İlanlar Listesi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('adoption_posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Henüz ilan eklenmedi.",
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  var adoptionPosts = snapshot.data!.docs.where((doc) {
                    String type = doc['animalType'] ?? 'Tümü';
                    String city = doc['city'] ?? 'Tümü';

                    bool categoryMatch = _selectedCategory == 'Tümü' || type == _selectedCategory;
                    bool cityMatch = _selectedCity == null || _selectedCity == "Tümü" || city == _selectedCity;

                    return categoryMatch && cityMatch;
                  }).toList();

                  return ListView(
                    children: adoptionPosts.map((post) {
                      var data = post.data() as Map<String, dynamic>;
                      return _buildAdoptionCard(data);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String category) {
    bool isSelected = _selectedCategory == category;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey, width: 2),
        ),
      ),
      onPressed: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Text(category, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }


  Widget _buildCityDropdown() {
    return Column(
      children: [
        Container(
          width: double.infinity, // **Kartın tam genişliği garanti!**
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.location_city, color: Colors.purple, size: 30),
                      SizedBox(width: 12),
                      Text(
                        "Şehir Filtresi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity, // **Dropdown'un genişliğini belirledik**
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true, // Bunu EKLE!
                        hint: const Text("Şehir seçiniz", style: TextStyle(color: Colors.grey)),
                        items: _cityList.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city, style: const TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                        value: _selectedCity,
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedCity != null && _selectedCity != "Tümü")
          Center(
            child: Text(
              "$_selectedCity ilanları gösteriliyor",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCityInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.locationDot, color: Colors.purple, size: 16),
          const SizedBox(width: 8),
          Text(
            getCityText(),
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple),
          ),
        ],
      ),
    );
  }


  Widget _buildAdoptionCard(Map<String, dynamic> adopt) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Resim
            GestureDetector(
              onTap: () {
                if (adopt['imageUrl'] != null && adopt['imageUrl'].toString().isNotEmpty) {
                  _showImagePopup(context, adopt['imageUrl']);
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: adopt['imageUrl'] != null && adopt['imageUrl'].toString().isNotEmpty
                        ? Image.network(
                      adopt['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          width: double.infinity,
                          height: 220,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purple,
                              strokeWidth: 5,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 220,
                          color: Colors.grey[300],
                          child: const Center(child: Text("Resim yüklenemedi")),
                        );
                      },
                    )
                        : Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text("Fotoğraf Yok", style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 🏷️ İlan Tipi
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${adopt['animalType'] ?? "Belirtilmemiş"} İlanı',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF9346A1)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 📝 Açıklama
            Text(
              adopt['description'] ?? "Açıklama mevcut değil.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 5),

            // 🔗 Bölücü Çizgi
            Divider(color: Colors.grey[400]),
            const SizedBox(height: 5),

            // 👤 Kullanıcı Bilgisi (Adı + Şehir)
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: adopt['ownerId'], // Firestore'da kayıtlı kullanıcı ID'si
                          userEmail: adopt['ownerEmail'],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: (adopt['ownerProfileUrl'] != null && adopt['ownerProfileUrl'].toString().isNotEmpty)
                            ? NetworkImage(adopt['ownerProfileUrl'].toString())
                            : const AssetImage('assets/images/avatar1.png') as ImageProvider<Object>,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${adopt['ownerName'] ?? "Bilinmiyor"} - ${adopt['city'] ?? "Şehir Belirtilmemiş"}',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 📩 Mesaj Gönder Butonu
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openChatWithOwner(adopt['ownerEmail']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9346A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(FontAwesomeIcons.facebookMessenger, color: Colors.white),
                label: const Text('Mesaj Gönder', style: TextStyle(color: Colors.white)),
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => _showReportDialog(context, adopt),
                icon: Icon(Icons.flag, color: Colors.redAccent),
                label: Text("Bu ilanı bildir", style: GoogleFonts.poppins(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, Map<String, dynamic> postData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("İlanı Bildir"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text("Müstehcen içerik"),
                    value: "Müstehcen içerik",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("Spam / Rahatsız edici"),
                    value: "Spam / Rahatsız edici",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("Sahte içerik"),
                    value: "Sahte içerik",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("Diğer"),
                    value: "Diğer",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("İptal", style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                    Navigator.pop(ctx);

                    final reportedUserId = postData['ownerId'];
                    final reportedUserSnapshot = await FirebaseFirestore.instance.collection('users').doc(reportedUserId).get();
                    final reportedUserData = reportedUserSnapshot.data();

                    await FirebaseFirestore.instance.collection('complaints').add({
                      'type': 'Sahiplendirme',
                      'contentId': postData['id'] ?? '',
                      'reportedBy': user.email,
                      'reason': selectedReason,
                      'timestamp': FieldValue.serverTimestamp(),
                      'reportedUser': {
                        'id': reportedUserId,
                        'email': reportedUserData?['email'] ?? 'Bilinmiyor',
                      }
                    });


                    // 👇 Kısa gecikme ekliyoruz
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (!context.mounted) return;

                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: "Teşekkürler",
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return const Material(
                          type: MaterialType.transparency,
                          child: SizedBox.expand(),
                        );
                      },
                      transitionBuilder: (context, anim1, anim2, child) {
                        final curvedValue = Curves.easeOutBack.transform(anim1.value);
                        return Opacity(
                          opacity: anim1.value,
                          child: Transform.scale(
                            scale: curvedValue,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                margin: const EdgeInsets.symmetric(horizontal: 32),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 26),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        "İlanı bildirdiğiniz için teşekkür ederiz 💚",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.none,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );

                    Future.delayed(const Duration(seconds: 2), () {
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).maybePop();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedReason != null ? Colors.purple : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Bildir"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _openChatWithOwner(String? ownerEmail) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mesaj göndermek için giriş yapmalısınız.")),
      );
      return;
    }

    if (ownerEmail == null || ownerEmail.isEmpty) {
      print("❌ HATA: İlan sahibinin email bilgisi yok!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İlan sahibinin iletişim bilgisi bulunamadı.")),
      );
      return;
    }

    print("📨 Sohbet açılıyor: ${currentUser.email} -> $ownerEmail");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverEmail: ownerEmail,
        ),
      ),
    );
  }

  void _showImagePopup(BuildContext context, String imageUrl) {
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
                  child: Image.network(imageUrl, width: 500, height: 500, fit: BoxFit.contain),
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
