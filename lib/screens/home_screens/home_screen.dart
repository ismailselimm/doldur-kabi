import 'dart:async';
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
import '../../widgets/report_dialog.dart';
import '../intro/intro_screen.dart';
import 'emergency_report_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:doldur_kabi/widgets/feeding_point_popup_widget.dart';
import 'package:doldur_kabi/widgets/cathouse_popup_widget.dart';

import 'home_info_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // İlk önce konum izni
    _initializeApp(); // Sonra uygulama başlat
    _listenForMarkerUpdates(); // Son olarak dinlemeye başla
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
            zIndex: 2, // 🔥 DİKKAT: mama kabı hep üstte
            icon: await getResizedMarker(
              "assets/images/" +
                  (() {
                    final timestamp = data['lastFilled'];
                    final isBos = timestamp != null
                    ? DateTime.now().difference((timestamp as Timestamp).toDate()).inHours >= 3
                        : true;
                    final animal = data['animal'] ?? 'cat';
                    final base = isBos
                    ? (animal == 'cat' ? 'catfoodbos.png' : 'dogfoodbos.png')
                        : (animal == 'cat' ? 'catfood.png' : 'dogfood.png');
                    return base;
                  })(),
              (_selectedPoint == doc.id) ? 160 : 110,
              (_selectedPoint == doc.id) ? 160 : 110,
            ),

            onTap: () async {
              final timestamp = data['lastFilled'];
              final isBos = timestamp == null || DateTime.now().difference((timestamp as Timestamp).toDate()).inHours >= 3;

              setState(() {
                _selectedPoint = doc.id;
                _fillingStates.putIfAbsent(doc.id, () => false);
                _selectedLastFilled = timestamp;
                _lastFilledImageUrl = data['lastFilledImageUrl'];
                _selectedPosition = adjustedPosition;
                _selectedIsAnimalHouse = false;
                _selectedAnimalType = (data['animal'] == 'cat') ? 'Kedi' : 'Köpek';
                _fillCompletedStates[doc.id] = timestamp != null;
              });

              await _loadMarkersFromFirestore();

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
                        "${isBos ? '🔴' : '🟢'}  Mama Kabı (${_selectedAnimalType})",
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
      QuerySnapshot animalHousesSnapshot = await firestore
          .collection('animalHouses')
          .where('isApproved', isEqualTo: true)
          .get();
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
            zIndex: 2, // 🔥 Hayvan evleri de üstte
            icon: (_selectedPoint == doc.id)
                ? await getResizedMarker("assets/images/pethouse.png", 160, 160)
                : (data['animal'] == 'cat' ? _catAnimalHouseIcon! : _dogAnimalHouseIcon!),
            onTap: () async {
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

              await _loadMarkersFromFirestore(); // 🔥 Marker'ları güncelle (boyutlandırma dahil)


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
                      Text(
                        _selectedAnimalType == 'Kedi' ? "Kedi Evi 🏠" : "Köpek Evi 🏠",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    _catFeedingPointIcon = await getResizedMarker("assets/images/catfood.png", 110, 110);
    _dogFeedingPointIcon = await getResizedMarker("assets/images/dogfood.png", 110, 110);
    _catAnimalHouseIcon = await getResizedMarker("assets/images/pethouse.png", 120, 120);
    _dogAnimalHouseIcon = await getResizedMarker("assets/images/pethouse.png", 120, 120);
  }


  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Konum izni gerekli! Varsayılan konum kullanılıyor."),
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Varsayılan konum ayarla
        setState(() {
          _currentPosition = LatLng(41.0082, 28.9784);
        });
        return;
      }

      await _getCurrentLocation();

    } catch (e) {
      print("❌ İzin kontrolü hatası: $e");
      setState(() {
        _currentPosition = LatLng(41.0082, 28.9784);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Konum servisi açık mı kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ Konum servisi kapalı, varsayılan konum kullanılıyor");
        setState(() {
          _currentPosition = LatLng(41.0082, 28.9784); // İstanbul varsayılan
        });
        return;
      }

      // İzin kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print("❌ Konum izni reddedildi, varsayılan konum kullanılıyor");
        setState(() {
          _currentPosition = LatLng(41.0082, 28.9784); // İstanbul varsayılan
        });
        return;
      }

      // Konum al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10), // ⭐ Zaman aşımı ekle
      );

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;

        // Kendi marker'ını sil ve tekrar ekle
        _markers.removeWhere((marker) => marker.markerId.value == "current_location");


      });

      // Kamerayı odakla
      if (_controller != null) {
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newPosition, zoom: 17.0),
          ),
        );
      }

      print("✅ Konum başarıyla alındı: $newPosition");

    } catch (e) {
      print("❌ Konum alınamadı: $e");
      // Hata durumunda varsayılan konumu ayarla
      setState(() {
        _currentPosition = LatLng(41.0082, 28.9784); // İstanbul varsayılan
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;

    if (_currentPosition != null) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 17.0),
        ),
      );
    }

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
    final isCat = (_selectedAnimalType?.toLowerCase() == 'kedi');

    final titleText = _selectedIsAnimalHouse
        ? "${_selectedAnimalType ?? 'Hayvan'} Evi"
        : isCat
        ? "   Kediler İçin\n   Mama Kabı"
        : "   Köpekler İçin\n    Mama Kabı";

    final leadingEmoji = _selectedIsAnimalHouse
        ? "     🏠"
        : isCat
        ? "  🐈"
        : " 🦮";


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
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false,

          // 👇 Sol üstteki hızlı menü butonu
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.house, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IntroScreen()),
              );
            },
          ),

          // 👇 Sağ üstteki bildirim butonu
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
            _currentPosition != null
                ? GoogleMap(
              zoomControlsEnabled: false,
              myLocationEnabled: true, // 👈 mavi konum ikonunu gösterir
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;

                final safePosition = _currentPosition ?? const LatLng(41.0082, 28.9784);
                _controller?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: safePosition, zoom: 17.0),
                  ),
                );
                setState(() {});
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(41.0082, 28.9784),
                zoom: 14.0,
              ),
              markers: _markers,
              onTap: (_) async {
                if (_selectedPoint != null || _selectedPosition != null) {
                  setState(() {
                    _selectedPoint = null;
                    _selectedPosition = null;
                  });

                  _customInfoWindowController.hideInfoWindow!();
                  await Future.delayed(const Duration(milliseconds: 50));
                  await _loadMarkersFromFirestore();
                }
              },
              onLongPress: _addMarker,
            )
                : const Center(child: CircularProgressIndicator()),


            // AppBar'ın altına, sol üst köşeye soru işareti butonu
            Positioned(
              top: 15,
              left: 15,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeInfoScreen()),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.circleQuestion,
                      color: Colors.purple,
                      size: 21,
                    ),
                  ),
                ),
              ),
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

            // NOKTALARA BAĞLI KUTUCUKLAR BURADA
            if (_selectedPosition != null)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 120,
                top: MediaQuery.of(context).size.height / 2 - 100,
                child: _selectedIsAnimalHouse
                    ? CathousePopupWidget(
                  titleText: titleText,
                  leadingEmoji: leadingEmoji,
                  imageUrl: _lastFilledImageUrl,
                  timestamp: _selectedLastFilled,
                  onReportPressed: () => _showReportBottomSheet(context),
                  onImageTap: _lastFilledImageUrl != null
                      ? () => _showImagePopup(context, _lastFilledImageUrl!)
                      : null,
                )
                    : FeedingPointPopupWidget(
                  isCat: (_selectedAnimalType?.toLowerCase() == 'kedi'),
                  isFilling: isFilling,
                  isFilled: isFilled,
                  titleText: titleText,
                  leadingEmoji: leadingEmoji,
                  imageUrl: _lastFilledImageUrl,
                  timestamp: _selectedLastFilled,
                  onFillPressed: () {
                    if (_auth.currentUser == null) {
                      showTopSnackBar(
                        context,
                        "Mama kabını doldurmak için giriş yapmanız gerekmektedir. 🐶🐱",
                      );
                      return;
                    }
                    _startFillingAnimation();
                    _fillCompleted = true;
                  },
                  onReportPressed: () => _showReportBottomSheet(context),
                  onImageTap: _lastFilledImageUrl != null
                      ? () => _showImagePopup(context, _lastFilledImageUrl!)
                      : null,
                ),
              ),

            // Filtre butonları ve veteriner simgesi
            Positioned(
              top: 15,
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
                                MaterialPageRoute(builder: (context) => const ShelterListScreen()), // Barınak sayfası
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


      floatingActionButton: _currentPosition == null
          ? null
          : Padding(
        padding: const EdgeInsets.only(bottom: 0), // 🔼 ALT YUKARI ALIR
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FloatingActionButton(
              heroTag: 'addFeedingPointFab',
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
              heroTag: 'addCathouseFab',
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
              heroTag: 'goToMyLocationFab',
              backgroundColor: Colors.white,
              onPressed: () {
                if (_currentPosition != null && _controller != null) {
                  final position = _currentPosition ?? const LatLng(41.0082, 28.9784);
                  _controller?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: position, zoom: 17.0),
                    ),
                  );

                }
              },
              child: const Icon(Icons.my_location, color: Colors.purple, size: 30),
            ),
          ],
        ),
      ),

    );
  }

  Future<String?> _getEmailFromUid(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['email'];
      }
    } catch (e) {
      print("❌ Kullanıcı maili alınamadı: $e");
    }
    return null;
  }

  void showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 80,
        left: 20,
        right: 90, // 👈 sağdan boşluk artırıldı
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => overlayEntry.remove(),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Otomatik kapanma
    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
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
      _fillCompleted = false;
    });

    await _confirmFillingPoint();

    if (!mounted) return;
    setState(() {
      _fillCompleted = _fillCompletedStates[pointId] ?? false;
      _selectedPosition = _selectedPosition; // 🔁 UI’yi yenile
    });

    final updatedDoc = await _firestore.collection('feedPoints').doc(pointId).get();
    if (updatedDoc.exists) {
      final data = updatedDoc.data()!;
      setState(() {
        _selectedLastFilled = data['lastFilled'];
        _lastFilledImageUrl = data['lastFilledImageUrl'];
        _fillCompletedStates[pointId] = true;
        _fillingStates[pointId] = false;
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

    // 📸 Fotoğraf kaynağını sor
    final source = await _showImageSourceDialog();
    if (source == null) {
      print("❌ Kullanıcı vazgeçti, doldurma işlemi iptal edildi.");
      return; // ✅ VAZGEÇ'E BASILDIYSA BURADA KES
    }

    // 📷 Fotoğraf seçilsin
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) {
      print("❌ Fotoğraf seçilmedi.");
      return; // ✅ Kamera/galeriden de geri döndüyse çık
    }

    // 🔄 Devam: zaman güncelle, kayıt yap, puan ekle vs.
    Timestamp newTimestamp = Timestamp.now();
    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance.ref().child('feed_point_images/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    try {
      await _firestore.collection('feedPoints').doc(_selectedPoint).update({
        'lastFilled': newTimestamp,
        'lastFilledImageUrl': url,
      });

      await _firestore.collection('feeding_records').add({
        'userId': userID,
        'feedPointId': _selectedPoint,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userID).update({
        'mamaDoldurmaSayisi': FieldValue.increment(1),
      });
      print("👤 Firebase UID: $userID");



      setState(() {
        _selectedLastFilled = newTimestamp;
        _lastFilledImageUrl = url;
        _fillCompletedStates[_selectedPoint!] = true;
        _fillingStates[_selectedPoint!] = false;
        _fillCompleted = true;
      });

      print("✅ Doldurma başarıyla tamamlandı!");
    } catch (e) {
      print("❌ Firebase güncelleme hatası: $e");
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

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF6EFFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
        title: const Row(
          children: [
            Icon(FontAwesomeIcons.image, color: Color(0xFF822E8A)),
            SizedBox(width: 12),
            Text(
              "Mama Kabı Fotoğrafı",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Fotoğrafı nasıl eklemek istersin?",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, ImageSource.camera),
                  icon: const Icon(FontAwesomeIcons.camera, size: 18),
                  label: const Text("Kamera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF822E8A),
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
                    backgroundColor: const Color(0xFF822E8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    elevation: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                "Vazgeç",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: const BoxConstraints(
        maxHeight: 110,
        minHeight: 110,
      ),
      builder: (context) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          leading: const Icon(Icons.flag, color: Colors.redAccent),
          title: const Text(
            "Bu içeriği bildir",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onTap: () async {
            Navigator.of(context).pop();

            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              showTopSnackBar(context, "Lütfen giriş yapın");
              return;
            }

            final collection = _selectedIsAnimalHouse ? 'animalHouses' : 'feedPoints';
            final doc = await FirebaseFirestore.instance
                .collection(collection)
                .doc(_selectedPoint!)
                .get();

            final data = doc.data();
            final addedByUid = data?['addedBy'];
            final targetUserEmail = addedByUid != null
                ? (await _getEmailFromUid(addedByUid)) ?? 'unknown@doldurkabi.com'
                : 'unknown@doldurkabi.com';

            WidgetsBinding.instance.addPostFrameCallback((_) {
              showReportDialog(
                context,
                targetType: _selectedIsAnimalHouse ? 'Hayvan Evi' : 'Mama Kabı',
                targetId: _selectedPoint!,
                targetUserEmail: targetUserEmail,
                targetTitle: _selectedIsAnimalHouse
                    ? '${_selectedAnimalType ?? 'Hayvan'} Evi'
                    : '${_selectedAnimalType ?? 'Mama'} Kabı',
              );
            });
          },
        );
      },
    );
  }
}

