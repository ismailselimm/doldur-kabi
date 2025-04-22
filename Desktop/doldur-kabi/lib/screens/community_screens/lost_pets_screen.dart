import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doldur_kabi/screens/community_screens/add_lost_pet_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LostPetsScreen extends StatefulWidget {
  @override
  _LostPetsScreenState createState() => _LostPetsScreenState();
}

class _LostPetsScreenState extends State<LostPetsScreen> {
  String selectedCategory = "Tümü";
  String _selectedCity = "Tümü"; // Varsayılan olarak "Tümü" seçili olacak

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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 33),
            tooltip: 'Kayıp Hayvan İlanı Ver',
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
                    _buildStackedCategoryButton("Kedi"),
                    _buildStackedCategoryButton("Köpek"),
                  ],
                ),
                const SizedBox(height: 10), // Boşluk ekleyelim

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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    isExpanded: true,
                    menuMaxHeight: 250, // Maksimum yükseklik (5 şehir gösterir)
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.purple), // 🎨 Şık ikon
                    decoration: const InputDecoration(border: InputBorder.none), // Alt çizgiyi kaldır
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
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('lost_pets').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Henüz kayıp hayvan ilanı eklenmedi.",
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                var lostPets = snapshot.data!.docs.where((doc) {
                  String type = doc['petType'] ?? 'Tümü';
                  String city = doc['city'] ?? 'Tümü';

                  bool categoryMatch = selectedCategory == 'Tümü' || type == selectedCategory.split(" ")[0];
                  bool cityMatch = _selectedCity == "Tümü" || city == _selectedCity;

                  return categoryMatch && cityMatch;
                }).toList();


                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: lostPets.map((doc) => _buildLostPetCard(doc.data() as Map<String, dynamic>)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedCategoryButton(String topText) {
    bool isSelected = selectedCategory.contains(topText);

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
          selectedCategory = "$topText";
        });
      },
      child: Column(
        children: [
          Text(topText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
    String? imageUrl = pet['imageUrl']; // Firebase'den gelen URL

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                _showImagePopup(context, imageUrl ?? _getDefaultImage(pet['petType']));
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: 200,
                      width: 200,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.purple, // 🎨 Mor renkli yükleniyor çemberi
                              strokeWidth: 5, // Daha kalın çember
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          _getDefaultImage(pet['petType']),
                          fit: BoxFit.cover,
                          height: 200,
                          width: 200,
                        );
                      },
                    )
                        : Image.asset(
                      _getDefaultImage(pet['petType']),
                      fit: BoxFit.cover,
                      height: 200,
                      width: 200,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['petName'] ?? "Bilinmeyen",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "📍 ${pet['location'] ?? 'Bilinmiyor'}",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _makePhoneCall(pet['phone']);
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text("Ara", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showReportDialog(context, pet),
                        child: Text(
                          "Bu ilanı bildir",
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // 🔥 PET TÜRÜNE GÖRE VARSAYILAN RESMİ SEÇEN FONKSİYON
  String _getDefaultImage(String? petType) {
    if (petType == "Kedi") {
      return 'assets/images/kayipkedi.jpg';
    } else if (petType == "Köpek") {
      return 'assets/images/kayipkopek.jpeg';
    } else {
      return 'assets/images/default_pet.jpg'; // Eğer bilinmeyen bir türse genel bir varsayılan resim koy
    }
  }


  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
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

                    // Kullanıcı bilgilerini alalım
                    final reportedUserId = postData['userId'];
                    final reportedUserSnapshot = await FirebaseFirestore.instance.collection('users').doc(reportedUserId).get();
                    final reportedUserData = reportedUserSnapshot.data();

                    await FirebaseFirestore.instance.collection('complaints').add({
                      'type': 'Kayıp',
                      'contentId': postData['id'] ?? '',
                      'reportedBy': user.email,
                      'reason': selectedReason,
                      'timestamp': FieldValue.serverTimestamp(),
                      'reportedUser': {
                        'id': reportedUserId,
                        'email': reportedUserData?['email'] ?? 'Bilinmiyor',
                      }
                    });

                    await Future.delayed(const Duration(milliseconds: 100));
                    if (!context.mounted) return;

                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: "Teşekkürler",
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) => const Material(type: MaterialType.transparency, child: SizedBox.expand()),
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
                  child: Image.network(
                    imageUrl,
                    width: 500,
                    height: 500,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/default_pet.jpg', // Varsayılan resim
                        width: 500,
                        height: 500,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
