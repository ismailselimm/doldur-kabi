import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../login_screens/login_screen.dart';

class AddCathouseScreen extends StatefulWidget {
  @override
  _AddCathouseScreenState createState() => _AddCathouseScreenState();
}

class _AddCathouseScreenState extends State<AddCathouseScreen> {
  Position? _currentPosition;
  String? _selectedAnimal;
  String? _currentAddress;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _checkUserLoginStatus();
  }

  /// **🔥 Kullanıcı giriş yapmamışsa alert göster**
  void _checkUserLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginAlert();
      });
    } else {
      _getCurrentLocation();
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
            "Hayvan Evi Ekleme",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[700]),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Hayvan evi ekleyebilmek için giriş yapmalısınız.",
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


  Future<void> _saveAnimalHouse() async {
    if (_selectedAnimal == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen hayvan türü seçin ve bir konum belirleyin.")),
      );
      return;
    }

    try {
      // **🔥 1️⃣ Yeni hayvan evi ekleniyor**
      await FirebaseFirestore.instance.collection('animalHouses').add({
        'animal': _selectedAnimal,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _currentAddress ?? 'Bilinmeyen adres',
        'date': DateTime.now(),
        'addedBy': FirebaseAuth.instance.currentUser!.uid, // **🔥 Kullanıcı eklediğini belirtelim**
      });

      // **🔥 2️⃣ Kullanıcı profilinde hayvan evi sayısını artır**
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hayvanEviSayisi': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yeni hayvan evi başarıyla kaydedildi!")),
      );

      SelectedIndex.changeSelectedIndex(0);
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));

      print("✅ Hayvan evi başarıyla eklendi ve kullanıcı profili güncellendi!");
    } catch (e) {
      print("❌ Firestore hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt sırasında bir hata oluştu, tekrar deneyin.")),
      );
    }
  }


  Widget _buildAnimalOption(String name, String imagePath, String animalType) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnimal = animalType;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _selectedAnimal == animalType ? Colors.white70 : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                const BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 2),
              ],
            ),
            child: Image.asset(imagePath, width: 60, height: 60),
          ),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _getAddressFromLatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 17));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Konum alınamadı. Lütfen konum servislerini kontrol edin.")),
      );
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
        });
      } else {
        setState(() {
          _currentAddress = "Adres bulunamadı";
        });
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        _currentAddress = "Adres alınırken hata oluştu";
      });
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLatLng(location.latitude, location.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yeni Hayvan Evi Ekle',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Color(0xFF9346A1),
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Ev Türünü Seçin:", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimalOption("Kedi", "assets/images/cat.png", "cat"),
                _buildAnimalOption("Köpek", "assets/images/dog.png", "dog"),
              ],
            ),
            SizedBox(height: 5),
            if (_currentAddress != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "Adres: $_currentAddress",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                  ),
                ),
              ),
            SizedBox(height: 20),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF9346A1), width: 3), // Mor çerçeve ekledik
                borderRadius: BorderRadius.circular(12), // Köşeleri yumuşattık
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // Haritayı da köşelerden yuvarladık
                child: GoogleMap(
                  initialCameraPosition: _selectedLocation != null
                      ? CameraPosition(target: _selectedLocation!, zoom: 17)
                      : CameraPosition(target: LatLng(37.7749, -122.4194), zoom: 15),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 17));
                    }
                  },
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {Marker(markerId: MarkerId("selected"), position: _selectedLocation!)}
                      : {},
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Ekleyeceğiniz konumu harita üzerinden kaydırarak veya sağ altta bulunan konum işaretine basarak seçiniz.",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selectedLocation == null
                  ? null
                  : () {
                _saveAnimalHouse();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF23B14D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                elevation: 4,
              ),
              child: Text(
                "Kaydet",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFFF8F8F8),
    );
  }
}