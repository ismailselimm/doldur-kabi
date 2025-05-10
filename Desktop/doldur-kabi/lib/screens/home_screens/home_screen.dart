import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/home_screens/shelter_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doldur_kabi/screens/home_screens/nearby_vets_screen.dart';
import 'package:doldur_kabi/screens/home_screens/add_feeding_point_screen.dart';
import 'package:doldur_kabi/screens/home_screens/add_cathouse_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:doldur_kabi/screens/home_screens/notification_screen.dart';
import 'package:flutter/services.dart';
import '../../functions/get_resized_marker.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'emergency_report_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


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
  Map<String, bool> _fillingStates = {};      // her noktanın doldurma animasyonu
  Map<String, bool> _fillCompletedStates = {}; // her noktanın doldurma tamam bilgisi
  String? _lastFilledImageUrl;


  LatLng offsetLatLng(LatLng original, int index) {
    const double offsetDistance = 0.00006; // 🔥 Bu değeri büyüttüm
    double dx = offsetDistance * (index % 3 - 1); // -1, 0, 1
    double dy = offsetDistance * ((index ~/ 3) - 1); // -1, 0, 1

    return LatLng(original.latitude + dy, original.longitude + dx);
  }



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
      int feedIndex = 0; // ✅ Index sayacı

      for (var doc in feedPointsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('latitude') || !data.containsKey('longitude')) continue;

        if (_selectedFilter != null && data['animal'] != _selectedFilter) continue;

        LatLng originalPosition = LatLng(data['latitude'], data['longitude']);
        LatLng adjustedPosition = offsetLatLng(originalPosition, feedIndex); // ✅ Offset uygula
        feedIndex++;

        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: adjustedPosition,
            icon: data['animal'] == 'cat' ? _catFeedingPointIcon! : _dogFeedingPointIcon!,
            onTap: () {
              setState(() {
                _selectedPoint = doc.id;
                _fillingStates.putIfAbsent(doc.id, () => false);
                _selectedLastFilled = data.containsKey('lastFilled') ? data['lastFilled'] : null;
                _lastFilledImageUrl = data['lastFilledImageUrl'];
                _selectedPosition = adjustedPosition;
                _selectedIsAnimalHouse = false;
                _selectedAnimalType = (data['animal'] == 'cat') ? 'Kedi' : 'Köpek';

                if (data.containsKey('lastFilled')) {
                  _fillCompletedStates[doc.id] = true;
                } else {
                  _fillCompletedStates[doc.id] = false;
                }
              });



              _customInfoWindowController.addInfoWindow!(
                Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "📍 Mama Kabı (${_selectedAnimalType})",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                adjustedPosition,
              );
            },
          ),
        );
      }

      // **2️⃣ Hayvan evlerini çek**
      QuerySnapshot animalHousesSnapshot = await firestore.collection('animalHouses').get();
      int houseIndex = 0;

      for (var doc in animalHousesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('latitude') || !data.containsKey('longitude')) continue;

        LatLng originalPosition = LatLng(data['latitude'], data['longitude']);
        LatLng adjustedPosition = offsetLatLng(originalPosition, houseIndex); // ✅ Offset uygula
        houseIndex++;

        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: adjustedPosition,
            icon: data['animal'] == 'cat' ? _catAnimalHouseIcon! : _dogAnimalHouseIcon!,
            onTap: () {
              if (_selectedPoint != doc.id) {
                setState(() {
                  _fillingStates.clear();
                  _fillCompletedStates.clear();
                });
              }

              setState(() {
                _selectedPoint = doc.id;
                _selectedLastFilled = data.containsKey('lastFilled') ? data['lastFilled'] : data['date'];
                _selectedPosition = adjustedPosition;
                _selectedIsAnimalHouse = true;
                _selectedAnimalType = (data['animal'] == 'cat') ? 'Kedi' : 'Köpek';

                _lastFilledImageUrl = data['imageUrl'];


                // Harita kutucuğu için ilk durum ataması
                _fillingStates.putIfAbsent(doc.id, () => false);
                _fillCompletedStates.putIfAbsent(doc.id, () => false);
              });

              _customInfoWindowController.addInfoWindow!(
                Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "🏠 Burası Hayvan Evi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (data.containsKey('imageUrl') && data['imageUrl'] is String && data['imageUrl'].toString().isNotEmpty)
                        FutureBuilder(
                          future: precacheImage(NetworkImage(data['imageUrl']), context),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return GestureDetector(
                                onTap: () => _showImagePopup(context, data['imageUrl']),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: 180,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox(
                                width: 180,
                                height: 100,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                adjustedPosition,
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
    final isFilling = _selectedPoint != null && _fillingStates[_selectedPoint] == true;
    final isFilled = _selectedPoint != null && _fillCompletedStates[_selectedPoint] == true;


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

            // Sol alt köşeye sabit Acil Durum butonu
            Positioned(
              bottom: 13,
              left: 15,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmergencyReportScreen()),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Acil\nDurum",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),



            // **Mama noktasına bağlı kutucuk**
            if (_selectedPosition != null)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 120,
                top: MediaQuery.of(context).size.height / 2 - 100,
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
                        _selectedIsAnimalHouse ? " Hayvan Evi 🏠" : "Mama Kabı (${_selectedAnimalType ?? 'Bilinmiyor'})",
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),

                      // 🔥 SADECE HAYVAN EVİ GÖRSEL + TARİH
                      if (_selectedIsAnimalHouse &&
                          _lastFilledImageUrl != null &&
                          _lastFilledImageUrl!.isNotEmpty)
                        Column(
                          children: [
                            if (_selectedLastFilled != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  "📅 Eklenme Tarihi: ${_formatTimestamp(_selectedLastFilled!)}",
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            GestureDetector(
                              onTap: () => _showImagePopup(context, _lastFilledImageUrl!),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _lastFilledImageUrl!,
                                  width: 180,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      width: 180,
                                      height: 100,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ],
                        ),



                      // 🔥 MAMA KABI AYNI KALDI
                      if (!_selectedIsAnimalHouse)
                        AnimatedSwitcher(
                          duration: const Duration(seconds: 1),
                          child: isFilling
                              ? const Text(
                            "⏳ Dolduruluyor...✅",
                            key: ValueKey(2),
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          )
                              : isFilled
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              if (_selectedLastFilled != null)
                                Text(
                                  "🟢 Son Doldurma Zamanı: \n  🕰️ ${_formatTimestamp(_selectedLastFilled!)}",
                                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                              const SizedBox(height: 8),
                              if (_lastFilledImageUrl != null &&
                                  _lastFilledImageUrl!.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _showImagePopup(context, _lastFilledImageUrl!),
                                  child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _lastFilledImageUrl!,
                                        width: 160,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const SizedBox(
                                            width: 160,
                                            height: 100,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.purple,
                                                strokeWidth: 4,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                              : const Text(
                            "🔴 Henüz Doldurulmadı",
                            key: ValueKey(4),
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),

                      const SizedBox(height: 8),

                      if (!_selectedIsAnimalHouse && !_fillCompleted)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            elevation: 4,
                            shadowColor: Colors.green.withOpacity(0.5),
                          ),
                          onPressed: () {
                            _startFillingAnimation();
                            _fillCompleted = true;
                          },
                          child: const Text(
                            "Doldur 🐈🐕",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
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
                  // 🐾 Veteriner butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10), // 🔥 Çevresel boşluk
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(0.1), // 🔥 İkon çevresi boşluk
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
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(0.1), // 🔥 Barınak ikonu çevresi boşluk
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ShelterListScreen()), // Barınak sayfası
                              );
                            },
                            child: Image.asset('assets/images/animal-shelter.png', width: 50, height: 50),
                          ),
                        ),
                      ],
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
            heroTag: 'addFeedingPointFab', // ✅ 1. FAB
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
            heroTag: 'addCathouseFab', // ✅ 2. FAB
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
            heroTag: 'goToMyLocationFab', // ✅ 3. FAB
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
    final pointId = _selectedPoint!;

    setState(() {
      _fillingStates[pointId] = true;
      _fillCompletedStates[pointId] = false;
    });

    await _confirmFillingPoint();
    final updatedDoc = await _firestore.collection('feedPoints').doc(_selectedPoint!).get();
    if (updatedDoc.exists) {
      final data = updatedDoc.data()!;
      setState(() {
        _selectedLastFilled = data['lastFilled'];
        _lastFilledImageUrl = data['lastFilledImageUrl'];
        _fillCompletedStates[_selectedPoint!] = true;
        _fillingStates[_selectedPoint!] = false;
        _fillCompleted = true;

      });
    }


    await Future.delayed(const Duration(seconds: 2));

    final docSnap = await _firestore.collection('feedPoints').doc(pointId).get();
    if (docSnap.exists) {
      final data = docSnap.data();
      setState(() {
        _selectedLastFilled = data?['lastFilled'];
        _fillingStates[pointId] = false;
        _fillCompletedStates[pointId] = true;
        _fillCompleted = true;
      });
    }

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

      // **3️⃣ Kullanıcının mamaDoldurmaSayisi değerini artır**
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

    // 📸 Fotoğraf yüklet
    final picked = await ImagePicker().pickImage(
      source: await _showImageSourceDialog(), // bu fonksiyonu birazdan ekleyeceğiz
    );

    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child('feed_point_images/$fileName');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // 🔥 Firestore'a URL'yi ekle
      await _firestore.collection('feedPoints').doc(_selectedPoint).update({
        'lastFilledImageUrl': url,
      });
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


  Future<ImageSource> _showImageSourceDialog() async {
    ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF6EFFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 4), // 👈 ALT BOŞLUK AZALTILDI
        title: Row(
          children: const [
            Icon(FontAwesomeIcons.image, color: Color(0xFF822E8A)),
            SizedBox(width: 12),
            Text(
              "Mama Kabı Fotoğrafı",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Fotoğrafı nasıl eklemek istersin?",
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(bottom: 10, top: 8), // 👈 BUTONLA ARADAKİ MESAFE AZALTILDI
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(FontAwesomeIcons.camera, size: 18),
            label: const Text("Kamera"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF822E8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 4,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(FontAwesomeIcons.image, size: 18),
            label: const Text("Galeri"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF822E8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
    return source ?? ImageSource.gallery;
  }

  void _showImagePopup(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ImagePopup",
      barrierColor: Colors.black.withOpacity(0.85), // direkt siyah arka plan
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final fadeIn = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

        return FadeTransition(
          opacity: fadeIn,
          child: Stack(
            children: [
              // 📸 ORTADAKİ GÖRSEL
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    width: MediaQuery.of(context).size.width * 0.85,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // ❌ KAPAT BUTONU
              Positioned(
                top: 40,
                right: 30,
                child: GestureDetector(
                  onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Icon(Icons.close, size: 32, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

