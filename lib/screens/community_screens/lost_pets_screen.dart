import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doldur_kabi/screens/community_screens/add_lost_pet_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/banner_widget.dart';
import '../../widgets/report_dialog.dart';
import '../home_screens/main_home_page.dart';
import '../login_screens/login_screen.dart';
import 'lost_pet_detail_screen.dart';


class LostPetsScreen extends StatefulWidget {
  @override
  _LostPetsScreenState createState() => _LostPetsScreenState();
}

class _LostPetsScreenState extends State<LostPetsScreen> {
  Map<String, Size> _imageSizes = {}; // 🔥 Resim boyutlarını cache’le
  String selectedCategory = "Tümü";
  String _selectedCity = "Tüm Şehirler"; // Varsayılan olarak "Tümü" seçili olacak
  final PageController _pageController = PageController();
  final PageController _imageController = PageController();
  int _currentPage = 0;


  final List<String> _cityList = [
    "Tüm Şehirler", "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Amasya", "Ankara", "Antalya", "Artvin", "Aydın",
    "Balıkesir", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı",
    "Çorum", "Denizli", "Diyarbakır", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir", "Gaziantep",
    "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Isparta", "Mersin", "İstanbul", "İzmir", "Kars",
    "Kastamonu", "Kayseri","KKTC (Kıbrıs)", "Kırklareli", "Kırşehir", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa",
    "Kahramanmaraş", "Mardin", "Muğla", "Muş", "Nevşehir", "Niğde", "Ordu", "Rize", "Sakarya",
    "Samsun", "Siirt", "Sinop", "Sivas", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Şanlıurfa",
    "Uşak", "Van", "Yozgat", "Zonguldak", "Aksaray", "Bayburt", "Karaman", "Kırıkkale", "Batman",
    "Şırnak", "Bartın", "Ardahan", "Iğdır", "Yalova", "Karabük", "Kilis", "Osmaniye", "Düzce"
  ];

  String getCityText() {
    if (_selectedCity == "Tüm Şehirler") {
      return "Tüm şehirlerdeki ilanlar gösteriliyor";
    } else if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      return "$_selectedCity şehrindeki ilanlar gösteriliyor";
    } else {
      return "Şehir bilgisi bulunamadı";
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _checkUserLoginStatus();
    });
  }

  void _checkUserLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginAlert();
    }
  }

  void _showLoginAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Kayıp Hayvanlar",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple[700]),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Hayvan kayıp ilanlarını görüntüleyebilmek ve bu özellikleri kullanabilmek için giriş yapmanız gerekmektedir.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: const Text("Giriş Yap", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 8), // 🔥 Butonlar arasına boşluk
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  SelectedIndex.changeSelectedIndex(0);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()), // 🔥 Giriş yapmadan anasayfaya yönlendir
                  );
                },
                child: const Text(
                  "Giriş Yapmadan Devam Et",
                  style: TextStyle(fontSize: 16, color: Colors.purple, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          if (user != null)
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildCategoryButton("Tümü")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildStackedCategoryButton("Kedi")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStackedCategoryButton("Köpek")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStackedCategoryButton("Kuş")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openCitySelector(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCity,
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.purple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🔥 Kayıp ilanları
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lost_pets')
                        .where('isApproved', isEqualTo: true) // 🔥 SADECE ONAYLANANLARI ÇEK
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              "Henüz kayıp hayvan ilanı eklenmedi.",
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      final rawDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final type = data['petType'] ?? '';
                        final city = data['city'] ?? '';
                        final categoryMatch = selectedCategory == 'Tümü' || type == selectedCategory;
                        final cityMatch = _selectedCity == "Tüm Şehirler" || city == _selectedCity;
                        return categoryMatch && cityMatch;
                      }).toList();

                      final List<Map<String, dynamic>> lostPets = rawDocs.map((doc) {
                        final map = doc.data() as Map<String, dynamic>;
                        map['id'] = doc.id;
                        map['userEmail'] = map['userEmail'] ?? '';
                        return map;
                      }).toList();

                      return Column(
                        children: List.generate(lostPets.length, (index) {
                          final pet = lostPets[index];

                          if (index > 0 && index % 6 == 0) {
                            return Column(
                              children: [
                                _buildLostPetCard(pet),
                                const SizedBox(height: 20),
                                const BannerWidget(),
                                const SizedBox(height: 10),
                              ],
                            );
                          } else {
                            return _buildLostPetCard(pet);
                          }
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _getPetEmoji(String? type) {
    if (type == 'Kedi') return '🐱';
    if (type == 'Köpek') return '🐶';
    if (type == 'Kuş') return '🐦';
    return '🐾';
  }


  Widget _buildLostPetCard(Map<String, dynamic> pet) {
    final List imageUrls = pet['imageUrls'] ?? [];
    final String name = pet['petName'] ?? "İsimsiz";
    final String type = pet['petType'] ?? "";
    final String location = pet['location'] ?? "Bilinmiyor";
    final String phone = pet['phone'] ?? "";
    final String emoji = _getPetEmoji(type);
    final String description = pet['description'] ?? "";
    final Timestamp? timestamp = pet['timestamp'];

    return StatefulBuilder(
      builder: (context, setState) {
        final PageController _controller = PageController();
        int _current = 0;
        Timer? _timer;

        // Otomatik kaydırmayı başlat
        if (imageUrls.length > 1) {
          _timer = Timer.periodic(const Duration(seconds: 4), (_) {
            if (_controller.hasClients) {
              _current = (_current + 1) % imageUrls.length;
              _controller.animateToPage(
                _current,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        // Dialog kapanınca Timer’ı temizle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) _timer?.cancel();
        });
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LostPetDetailScreen(pet: pet),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 Görsel alanı
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          controller: _controller,
                          itemCount: imageUrls.length,
                          onPageChanged: (index) => setState(() => _current = index),
                          itemBuilder: (_, index) {
                            return GestureDetector(
                              onTap: () => _showImagePopup(context, imageUrls.cast<String>(), index),
                              child: Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) =>
                                    Image.asset(_getDefaultImage(type), fit: BoxFit.cover),
                              )

                            );
                          },
                        ),
                        if (imageUrls.length > 1)
                          Positioned(
                            bottom: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(imageUrls.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: _current == index ? 8 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _current == index ? Colors.deepPurple : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 🔥 Bilgi alanı
                Expanded(
                  child: SizedBox(
                    height: 120, // Görsel ile aynı yükseklik
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🐾 İsim
                        Row(
                          children: [
                            Text(
                              "$emoji $name",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "| ${type.isNotEmpty ? '$type ilanı' : 'Kayıp ilanı'}",
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: Colors.purple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // 📍 Lokasyon + tür
                        Text(
                          "📍 $location",
                          style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87),
                        ),

                        const SizedBox(height: 4),

                        // 📝 Açıklama (varsa göster, yoksa boşluk al)
                        description.trim().isNotEmpty
                            ? Text(
                          description,
                          style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                            : const Spacer(),

                        const Spacer(), // 🔥 Altı sabitlemek için ek

                        // 🗓️ Tarih & detay
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timestamp != null
                                  ? "${timestamp.toDate().day.toString().padLeft(2, '0')}.${timestamp.toDate().month.toString().padLeft(2, '0')}.${timestamp.toDate().year}"
                                  : "",
                              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[600]),
                            ),
                            Text(
                              "Detay için tıkla",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Şehir Seç",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _cityList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = _cityList[index];
                  return ListTile(
                    title: Text(city, style: GoogleFonts.poppins(fontSize: 16)),
                    trailing: _selectedCity == city
                        ? const Icon(Icons.check, color: Colors.deepPurple)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
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
    } else if (petType == "Kuş") {
      return 'assets/images/kayipkus.jpg'; // 🔥 varsa bu resmi koy
    } else {
      return 'assets/images/default_pet.jpg';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<Size> _getImageSize(String imageUrl) async {
    if (_imageSizes.containsKey(imageUrl)) return _imageSizes[imageUrl]!;

    final Completer<Size> completer = Completer();
    final ImageStream imageStream = NetworkImage(imageUrl).resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      final size = Size(info.image.width.toDouble(), info.image.height.toDouble());
      _imageSizes[imageUrl] = size;
      completer.complete(size);
    });
    imageStream.addListener(listener);
    return completer.future;
  }


  void _showImagePopup(BuildContext context, List<String> imageUrls, int initialIndex) {
    PageController controller = PageController(initialPage: initialIndex);
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 500,
                        height: 500,
                        child: PageView.builder(
                          controller: controller,
                          itemCount: imageUrls.length,
                          onPageChanged: (index) => setState(() => currentIndex = index),
                          itemBuilder: (context, index) {
                            return Image.network(
                              imageUrls[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/default_pet.jpg',
                                  fit: BoxFit.contain,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // X KAPATMA
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white, size: 32),
                    ),
                  ),

                  // Dots
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(imageUrls.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: currentIndex == index ? 10 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: currentIndex == index ? Colors.purpleAccent : Colors.white54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Sayfa sayacı (örn. 2/3)
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Text(
                        "${currentIndex + 1}/${imageUrls.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}