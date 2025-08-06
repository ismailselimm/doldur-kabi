import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/community_screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doldur_kabi/screens/community_screens/adoption_post_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/banner_widget.dart';
import '../../widgets/watermarked_Image.dart';
import '../home_screens/main_home_page.dart';
import '../login_screens/login_screen.dart';
import '../profile_screens/chat_screen.dart';
import 'adoption_detail_screen.dart';

class AdoptionScreen extends StatefulWidget {
  @override
  _AdoptionScreenState createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  Map<String, Size> _imageSizes = {}; // image boyutlarını sakla
  String _selectedCategory = 'Tümü';
  String? _selectedCity = "Tümü"; // 🏙️ Varsayılan olarak "Tümü"
  final List<String> _cityList = [
    "Tümü", "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Amasya", "Ankara", "Antalya", "Artvin", "Aydın",
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
    if (_selectedCity == "Tümü") {
      return "Tüm şehirlerdeki ilanlar gösteriliyor";
    } else if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      return "$_selectedCity şehrindeki ilanlar ";
    } else {
      return "Şehir bilgisi bulunamadı";
    }
  }




  @override

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _checkUserLoginStatus();
    });
  }

  Future<Size> _getImageSize(String imageUrl) async {
    if (_imageSizes.containsKey(imageUrl)) return _imageSizes[imageUrl]!;

    final Completer<Size> completer = Completer();
    final ImageStream imageStream = NetworkImage(imageUrl).resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      final size = Size(info.image.width.toDouble(), info.image.height.toDouble());
      _imageSizes[imageUrl] = size;
      completer.complete(size);
    }, onError: (dynamic exception, StackTrace? stackTrace) {
      completer.complete(const Size(1, 1)); // Hata varsa default 1:1
    });

    imageStream.addListener(listener);
    return completer.future;
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
            "Sahiplendirme Özellikleri",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[700]),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sahiplendirme ilanlarını görüntüleyebilmek ve bu özellikleri kullanabilmek için giriş yapmanız gerekmektedir.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Kategoriler
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tümü tek başına tam genişlik
                      _buildFilterButton('Tümü'),
                      const SizedBox(height: 10),

                      // Kedi - Köpek - Kuş yan yana
                      Row(
                        children: [
                          Expanded(child: _buildFilterButton('Kedi')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildFilterButton('Köpek')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildFilterButton('Kuş')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Şehir dropdown
                  GestureDetector(
                    onTap: () => _openCitySelector(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.1),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCity!,
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Şehir bilgisi kartı
                  Card(
                    elevation: 3,
                    color: Colors.purple.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.mapMarkerAlt, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            getCityText(),
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),


                  // İlanlar
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('adoption_posts')
                        .where('isApproved', isEqualTo: true) // ✨ Yalnızca onaylananlar
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Text(
                              "Henüz ilan eklenmedi.",
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      var adoptionPosts = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>?;

                        if (data == null) return false;

                        String type = data['animalType'] ?? 'Tümü';
                        String city = data['city'] ?? 'Tümü';
                        bool isAdopted = data.containsKey('isAdopted') ? data['isAdopted'] : false;

                        bool categoryMatch = _selectedCategory == 'Tümü' || type == _selectedCategory;
                        bool cityMatch = _selectedCity == null || _selectedCity == "Tümü" || city == _selectedCity;

                        return !isAdopted && categoryMatch && cityMatch;
                      }).toList();


                      List<Widget> postWidgets = [];

                      for (int i = 0; i < adoptionPosts.length; i++) {
                        var doc = adoptionPosts[i];
                        var data = doc.data() as Map<String, dynamic>;

                        // ✨ İlk ilan öncesi banner
                        if (i == 0) {
                          postWidgets.add(const SizedBox(height: 12));
                          postWidgets.add(const BannerWidget()); // 💥 imageList yok artık
                          postWidgets.add(const SizedBox(height: 12));
                        }

                        postWidgets.add(_buildAdoptionListTile(data, doc.id));

                        // ✨ Her 5 ilandan sonra bir banner
                        if ((i + 1) % 5 == 0 && i != adoptionPosts.length - 1) {
                          postWidgets.add(const SizedBox(height: 12));
                          postWidgets.add(const BannerWidget()); // 🔁 Tek satırda çağır
                          postWidgets.add(const SizedBox(height: 12));
                        }
                      }

                      return Column(children: postWidgets);

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

  void _openCitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.all(16),
          itemCount: _cityList.length,
          separatorBuilder: (_, __) => Divider(),
          itemBuilder: (context, index) {
            final city = _cityList[index];
            return ListTile(
              title: Text(
                city,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              trailing: _selectedCity == city
                  ? Icon(Icons.check, color: Colors.deepPurple)
                  : null,
              onTap: () {
                setState(() {
                  _selectedCity = city;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }


  Widget _buildAdoptionListTile(Map<String, dynamic> adopt, String docId){
    final String imageUrl = adopt['imageUrl'] ?? '';
    final String animalType = adopt['animalType'] ?? 'Hayvan';
    final String city = adopt['city'] ?? 'Bilinmeyen';
    final String description = adopt['description'] ?? 'Açıklama yok';
    final Timestamp? timestamp = adopt['timestamp'];


    String relativeDate = _getRelativeDate(timestamp);
    bool isToday = relativeDate == "Bugün";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
            MaterialPageRoute(
              builder: (_) => AdoptionDetailScreen(
                adoptData: adopt,
                docId: docId,
              ),
            ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: imageUrl,
                child: WatermarkedImage(
                  imageUrl: imageUrl,
                  width: 100,
                  height: 100,
                  borderRadius: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Şehir ve ilan türü
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.purple[300]),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple[300],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 1.5, height: 14, color: Colors.purple[200]),
                      const SizedBox(width: 6),
                      Text(
                        "$animalType İlanı",
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Açıklama
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: Colors.grey[900],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Tarih ve üç nokta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 5),
                          isToday
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Bugün",
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                              : Text(
                            relativeDate,
                            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdoptionDetailScreen(
                                adoptData: adopt,
                                docId: docId,
                              ),
                            ),
                          );
                        },
                        label: Text(
                          "Detay için tıkla",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
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

  String _getRelativeDate(Timestamp? timestamp) {
    if (timestamp == null) return "Tarih yok";

    final now = DateTime.now();
    final postDate = timestamp.toDate();
    final difference = now.difference(postDate).inDays;

    if (difference == 0) {
      return "Bugün";
    } else if (difference == 1) {
      return "Dün";
    } else if (difference <= 30) {
      return "$difference gün önce";
    } else {
      return "${postDate.day.toString().padLeft(2, '0')}.${postDate.month.toString().padLeft(2, '0')}.${postDate.year}";
    }
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

  Widget _buildAdoptionCard(Map<String, dynamic> adopt) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(adopt['ownerId']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(); // veya loading placeholder
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userName = "${userData['firstName']} ${userData['lastName']}";
        final userImage = userData['profileUrl'] ?? '';

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📸 Resim (Aynı kalabilir)
                FutureBuilder<Size>(
                  future: _getImageSize(adopt['imageUrl']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }


                    final size = snapshot.data!;
                    final aspectRatio = size.width / size.height;

                    return GestureDetector(
                      onTap: () {
                        _showImagePopup(context, adopt['imageUrl']);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: Image.network(
                            adopt['imageUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9346A1),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  adopt['description'] ?? "Açıklama mevcut değil.",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                ),


                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userId: adopt['ownerId'],
                            userEmail: userData['email'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: (userImage.isNotEmpty)
                              ? NetworkImage(userImage)
                              : const AssetImage('assets/images/avatar1.png') as ImageProvider,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$userName - ${adopt['city'] ?? "Şehir Belirtilmemiş"}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.purple),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        _openChatWithOwner(userData['email']);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(FontAwesomeIcons.paperPlane, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              "Mesaj Gönder",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showReportDialog(context, adopt),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent, width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flag, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              "İlanı Bildir",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
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