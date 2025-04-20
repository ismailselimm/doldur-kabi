import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doldur_kabi/screens/home_screens/nearby_vets_screen.dart';
import 'package:doldur_kabi/screens/home_screens/add_feeding_point_screen.dart';
import 'package:doldur_kabi/screens/home_screens/add_cathouse_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:doldur_kabi/screens/home_screens/notification_screen.dart';
import 'package:flutter/services.dart';
import '../../functions/get_resized_marker.dart';
import 'package:custom_info_window/custom_info_window.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController();
  bool _selectedIsAnimalHouse = false;
  LatLng? _selectedPosition;
  String? _selectedPoint;
  Timestamp? _selectedLastFilled;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  GoogleMapController? _controller;
  String? _selectedAnimal;
  BitmapDescriptor? _personIcon;
  BitmapDescriptor? _catFeedingPointIcon;
  BitmapDescriptor? _dogFeedingPointIcon;
  BitmapDescriptor? _catAnimalHouseIcon;
  BitmapDescriptor? _dogAnimalHouseIcon;
  String? _selectedFilter; // "cat" veya "dog" olacak, null ise hepsi gösterilecek
  String? _selectedAnimalType; // Seçilen mama kabının türü (Kedi / Köpek)



  @override

  void initState() {
    super.initState();
    _checkLocationPermission();
    _initializeApp();
    // **🔥 Firestore'daki değişiklikleri dinlemeye başla!**
    _listenForMarkerUpdates();
  }
  Future<void> _initializeApp() async {
    print("🔥 Uygulama başlatılıyor...");
    await _setCustomMarker(); // 🔥 Marker ikonları yüklensin
    await _loadMarkersFromFirestore(); // 🔥 Firestore'dan veriler çekilsin
  }


  Future<void> _loadMarkersFromFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Set<Marker> newMarkers = {};

    try {
      print("🔥 Firestore'dan besleme noktaları çekiliyor...");

      // **1️⃣ Besleme noktalarını çek**
      QuerySnapshot feedPointsSnapshot = await _firestore.collection('feedPoints').get();
      for (var doc in feedPointsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
          print("⚠️ HATA: Eksik veri var! ${doc.id}");
          continue; // Eğer lokasyon eksikse ekleme!
        }

        // 🔥 Eğer filtreleme aktifse ve bu nokta uymuyorsa, eklemiyoruz
        if (_selectedFilter != null && data['animal'] != _selectedFilter) {
          continue;
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['latitude'], data['longitude']),
            icon: data['animal'] == 'cat' ? _catFeedingPointIcon! : _dogFeedingPointIcon!,
            onTap: () {
              print("📌 INFO: ${doc.id} noktasına basıldı, lastFilled: ${data.containsKey('lastFilled') ? data['lastFilled'] : 'Yok'}");

              setState(() {
                _selectedPoint = doc.id;
                _selectedLastFilled = data.containsKey('lastFilled') ? data['lastFilled'] : null;
                _selectedPosition = LatLng(data['latitude'], data['longitude']);
                _selectedIsAnimalHouse = false; // Besleme noktası olduğu için false

                // 🔥 Burada hayvan türünü ekliyoruz!
                _selectedAnimalType = (data.containsKey('animal') && data['animal'] != null)
                    ? (data['animal'] == 'cat' ? 'Kedi' : 'Köpek')
                    : 'Bilinmiyor'; // Eğer animal alanı yoksa, varsayılan olarak bilinmiyor gösterme!
              });

              _customInfoWindowController.addInfoWindow!(
                Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "📍 Mama Kabı (${_selectedAnimalType})", // 🔥 Artık "Bilinmiyor" yerine kedi veya köpek yazacak
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                LatLng(data['latitude'], data['longitude']),
              );
            },

          ),
        );
      }

      // **2️⃣ Hayvan evlerini çek**
      QuerySnapshot animalHousesSnapshot = await firestore.collection('animalHouses').get();
      for (var doc in animalHousesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
          print("⚠️ HATA: Eksik veri var! ${doc.id}");
          continue; // Eğer lokasyon eksikse ekleme!
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['latitude'], data['longitude']),
            icon: data['animal'] == 'cat' ? _catAnimalHouseIcon! : _dogAnimalHouseIcon!,
            onTap: () {
              print("📌 INFO: ${doc.id} Hayvan Evi noktasına basıldı");

              setState(() {
                _selectedPoint = doc.id;
                _selectedPosition = LatLng(data['latitude'], data['longitude']);
                _selectedIsAnimalHouse = true;
              });

              _customInfoWindowController.addInfoWindow!(
                Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "🏠 Burası Hayvan Evi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                LatLng(data['latitude'], data['longitude']),
              );
            },
          ),
        );
      }

      // **🔥 Marker'ları Güncelle**
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value != "current_location");
        _markers.addAll(newMarkers);
      });

      print("✅ Firestore'dan markerlar yüklendi!");
    } catch (e) {
      print("❌ Firestore'dan markerları çekerken hata oluştu: $e");
    }
  }


  Future<void> fixMissingAnimalFields() async {
    QuerySnapshot query = await FirebaseFirestore.instance.collection('feedPoints').get();
    for (var doc in query.docs) {
      var data = doc.data() as Map<String, dynamic>;

      // 🔥 Eğer animal alanı eksikse, güncelle!
      if (!data.containsKey('animal') || data['animal'] == null) {
        await FirebaseFirestore.instance.collection('feedPoints').doc(doc.id).update({
          'animal': 'cat', // Burada 'cat' veya 'dog' yapabilirsin
        });
        print("🔥 ${doc.id} için animal alanı eklendi!");
      }
    }
    print("✅ Tüm eksik animal alanları tamamlandı!");
  }



  void _addFirestoreMarker(LatLng position, String title, BitmapDescriptor icon, String pointID, Map<String, dynamic> data, [Timestamp? lastFilled]) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == pointID);
      _markers.add(
        Marker(
          markerId: MarkerId(pointID),
          position: position,
          icon: icon,
          onTap: () {
            print("📌 INFO: ${pointID} noktasına basıldı, lastFilled: $lastFilled");

            setState(() {
              _selectedPoint = pointID;
              _selectedLastFilled = lastFilled;
              _selectedPosition = position;
              _selectedIsAnimalHouse = (title == "Hayvan Evi");

              // 🔥 TÜM DÜZELTME BURADA: Türü direkt Firestore'dan al!
              _selectedAnimal = data.containsKey('animal') ? data['animal'] : null;

              // ✅ Debug için yazdır
              print("✅ Seçilen Mama Kabı Türü: ${_selectedAnimal}");
            });

            _customInfoWindowController.addInfoWindow!(
              Container(
                width: 230,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedIsAnimalHouse
                          ? "🏠 Burası Hayvan Evi"
                          : "📍 Mama Kabı (${_selectedAnimal == 'cat' ? 'Kedi' : 'Köpek'})",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              position,
            );
          },
        ),
      );
    });
  }

  Future<void> _setCustomMarker() async {
    _personIcon = await getResizedMarker("assets/images/person5.png", 135, 135);
    _catFeedingPointIcon = await getResizedMarker("assets/images/catfood.png", 125, 125);
    _dogFeedingPointIcon = await getResizedMarker("assets/images/dogfood.png", 125, 125);
    _catAnimalHouseIcon = await getResizedMarker("assets/images/pethouse.png", 130, 130);
    _dogAnimalHouseIcon = await getResizedMarker("assets/images/pethouse.png", 130, 130);
  }


  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konum izni gerekli!")),
      );
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (position != null) {
        LatLng newPosition = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentPosition = newPosition;

          // 🔥 Önce kendi marker'ını sil (varsa)
          _markers.removeWhere((marker) => marker.markerId.value == "current_location");

          // 🔥 Kendi konumunu ekle
          _markers.add(
            Marker(
              markerId: const MarkerId("current_location"),
              position: newPosition,
              infoWindow: const InfoWindow(title: "Mevcut Konum"),
              icon: _personIcon!,
            ),
          );
        });

        // 🔥 Kamerayı kendi konumuna odakla
        _controller?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: newPosition, zoom: 15.0),
        ));
      } else {
        _getCurrentLocation(); // Eğer konum alınamazsa tekrar dene
      }
    } catch (e) {
      print("⚠️ Konum alınamadı: $e");
      _getCurrentLocation();
    }
  }




  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 17.0),
      ),
    );
    setState(() {});
  }

  void _addMarker(LatLng position) {
    final String markerId = position.toString();
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
          infoWindow: InfoWindow(
            title: 'Besleme Noktası',
            snippet: _selectedAnimal != null ? 'Hayvan Türü: $_selectedAnimal' : 'Mama ve su bırakıldı',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🔥 UI ŞU ANDA _selectedPosition: $_selectedPosition");

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF9346A1),
          title: Text(
            'DoldurKabı',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white), // İkon rengini kontrol et
          automaticallyImplyLeading: false, // 🔥 Geri butonunu tamamen kaldır!
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push( context,MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // **Tüm ekranı kapsasın**
        onTap: () {
          if (_selectedPosition != null) {
            setState(() {
              _selectedPosition = null; // **Haritaya basınca kutucuk kapansın**
            });
            _customInfoWindowController.hideInfoWindow!(); // **Kutucuğun kapanmasını zorla**
            print("🔥 Haritaya basıldı, kutucuk kapatıldı!");
          }
        },
        child: Stack(
          children: [
            _currentPosition == null
                ? const Center(child: CircularProgressIndicator()) // Konum yüklenene kadar gösterilecek animasyon
                : GoogleMap(
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 12.0,
              ),
              markers: _markers,
              onTap: (_) {
                if (_selectedPosition != null) {
                  setState(() {
                    _selectedPosition = null; // **Haritaya basınca kutucuk kapansın**
                  });
                  _customInfoWindowController.hideInfoWindow!(); // **Kutucuğu zorla kapat**
                  print("🔥 Haritaya tıklandı, kutucuk kapatıldı!");
                }
              },
              onLongPress: _addMarker,
            ),

            // **Mama noktasına bağlı kutucuk**
            if (_selectedPosition != null)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 120, // **Ortala**
                top: MediaQuery.of(context).size.height / 2 - 100, // **Daha aşağı çek**
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedIsAnimalHouse ? "🏠 Hayvan Evi" : "📍 Mama Kabı (${_selectedAnimalType ?? 'Bilinmiyor'})",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (!_selectedIsAnimalHouse) // **Hayvan evinde bu çıkmasın!**
                        AnimatedSwitcher(
                          duration: const Duration(seconds: 1),
                          child: _isFilling
                              ? const Text(
                            "⏳ Dolduruluyor...✅",
                            key: ValueKey(2),
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          )
                              : _fillCompleted
                              ? Text(
                            "⏳ Dolduruluyor... ✅",
                            key: const ValueKey(3),
                            style: const TextStyle(fontSize: 14, color: Colors.green),
                          )
                              : Text(
                            _selectedLastFilled != null
                                ? "🟢 Son Doldurma Zamanı: \n ${_formatTimestamp(_selectedLastFilled!)}"
                                : (_fillCompleted ? "✅ Dolduruldu" : "🔴 Henüz Doldurulmadı"),
                            key: const ValueKey(2),
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (!_selectedIsAnimalHouse && !_fillCompleted) // **Hayvan evinde buton çıkmasın!**
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Arka plan yeşil
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Butonu iyice büyüttüm
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Daha sert köşeler
                              side: BorderSide(color: Colors.green.shade600, width: 2), // Koyu yeşil güçlü çerçeve
                            ),
                            elevation: 4, // Hafif gölge ekledim, güçlü dursun
                            shadowColor: Colors.green.withOpacity(0.5), // Hafif yeşil gölge
                          ),
                          onPressed: () {
                            _startFillingAnimation();
                            setState(() {
                              _fillCompleted = true; // **Doldurma tamamlandı**
                            });
                          },
                          child: Text(
                            "Doldur 🐈🐕",
                            style: TextStyle(
                              fontSize: 16, // Yazıyı iyice büyüttüm
                              fontWeight: FontWeight.bold, // Daha güçlü hissettirsin
                              color: Colors.white, // Beyaz yazı
                              letterSpacing: 1.2, // Hafif harf aralığıyla daha karizmatik duracak
                            ),
                          ),
                        ),

                    ],
                  ),
                ),
              ),

            // **Filtre butonları ve veteriner simgesi**
            Positioned(
              top: 16,
              right: 8,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildAnimalIcon('assets/images/cat.png', 'cat'),
                        const SizedBox(height: 8),
                        _buildAnimalIcon('assets/images/dog.png', 'dog'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NearbyVetsScreen()),
                        );
                      },
                      child: Image.asset('assets/images/veterinary.png', width: 45, height: 45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // **📌 Eksik olan FloatingActionButton'ları geri ekledim**
      floatingActionButton: _currentPosition == null
          ? null // Konum yüklenene kadar butonları göstermiyoruz
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFeedingPointScreen()),
              );
            },
            child: Image.asset('assets/images/pet-food1.png', width: 41),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCathouseScreen()),
              );
            },
            child: Image.asset('assets/images/pethouse2.png', width: 39),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () {
              if (_currentPosition != null && _controller != null) {
                _controller?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentPosition!, zoom: 17.0),
                  ),
                );
              }
            },
            child: const Icon(Icons.my_location, color: Colors.purple, size: 30),
          ),
        ],
      ),
    );
  }


  Widget _buildAnimalIcon(String imagePath, String animalType) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedFilter == animalType) {
            _selectedFilter = null; // Aynı butona tekrar basarsa filtreyi kaldır
          } else {
            _selectedFilter = animalType; // Yeni filtreyi uygula
          }
        });

        _loadMarkersFromFirestore(); // Markerları tekrar yükle
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedFilter == animalType ? Colors.white70 : Colors.transparent, // Seçilmişse rengi değiştir
          borderRadius: BorderRadius.circular(15),
        ),
        child: Image.asset(imagePath, width: 45, height: 45),
      ),
    );
  }


  bool _isFilling = false; // **Animasyon durumu**
  bool _fillCompleted = false; // **Doldurma tamamlandıysa kutucuk kapanmasın**

  Future<void> _startFillingAnimation() async {
    if (_selectedPoint == null) return;

    setState(() {
      _isFilling = true;  // **"Dolduruluyor..." animasyonu başlasın**
      _fillCompleted = false;
    });

// **Firestore'u async olarak güncelle**
    _confirmFillingPoint().then((_) {
      setState(() {
        _isFilling = false;  // **Animasyonu kapat**
        _fillCompleted = true;  // **"Dolduruldu ✅" yazısı gösterilsin**
      });

      // **Firestore'daki güncellenmiş veriyi tekrar al**
      FirebaseFirestore.instance
          .collection('feedPoints')
          .doc(_selectedPoint)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          setState(() {
            _selectedLastFilled = docSnapshot['lastFilled'];
          });
        }
      });
    });

    await Future.delayed(const Duration(seconds: 2)); // **2 saniye daha kalsın**
    setState(() {
      _fillCompleted = false; // **Sonra tekrar son doldurulma bilgisi gözüksün**
    });
  }

  Future<void> _confirmFillingPoint() async {
    if (_selectedPoint == null) return;

    String? userID = _auth.currentUser?.uid;
    if (userID == null) return;

    Timestamp newTimestamp = Timestamp.now();

    try {
      // **1️⃣ Besleme noktasının lastFilled değerini güncelle**
      await _firestore.collection('feedPoints').doc(_selectedPoint).update({
        'lastFilled': newTimestamp,
      });

      // **2️⃣ Kullanıcının mama doldurma kaydını ekle**
      await _firestore.collection('feeding_records').add({
        'userId': userID,
        'feedPointId': _selectedPoint,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // **3️⃣ Kullanıcının `mamaDoldurmaSayisi` değerini artır**
      await _firestore.collection('users').doc(userID).update({
        'mamaDoldurmaSayisi': FieldValue.increment(1), // 🔥 Kullanıcı mama doldurdukça 1 artır
      });

      // **4️⃣ Kullanıcıya puan ekle**
      await _addPoints(userID, 3);

      print("✅ $_selectedPoint için lastFilled, feeding_records ve kullanıcı sayısı güncellendi!");

      setState(() {
        _selectedLastFilled = newTimestamp;
        _fillCompleted = true;
      });

    } catch (e) {
      print("❌ Hata: $_selectedPoint lastFilled güncellenemedi! Hata: $e");
    }
  }



  void _listenForMarkerUpdates() {
    _firestore.collection('feedPoints').snapshots().listen((snapshot) {
      print("🔥 Firestore'da değişiklik algılandı! Markerlar güncelleniyor...");

      // **Güncellenen markerları çek**
      _loadMarkersFromFirestore();
    });
  }

  Future<void> _addPoints(String userID, int points) async {
    DocumentReference userRef = _firestore.collection('users').doc(userID);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      int currentPoints = (snapshot.data() as Map<String, dynamic>)['points'] ?? 0;
      transaction.update(userRef, {'points': currentPoints + points});
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day} ${_ayAdi(date.month)} ${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _ayAdi(int ay) {
    List<String> aylar = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    return aylar[ay - 1];
  }

  Future<void> fixMissingLastFilled() async {
    QuerySnapshot query = await _firestore.collection('feedPoints').get();
    for (var doc in query.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('lastFilled')) {
        await _firestore.collection('feedPoints').doc(doc.id).update({
          'lastFilled': FieldValue.serverTimestamp(),
        });
        print("🔥 ${doc.id} için lastFilled eklendi!");
      }
    }
    print("✅ Tüm eksik lastFilled alanları eklendi!");
  }

}