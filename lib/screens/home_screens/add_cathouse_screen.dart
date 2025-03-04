import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    _getCurrentLocation();
  }

  Future<void> _saveAnimalHouse() async {
    if (_selectedAnimal == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen hayvan türü seçin ve bir konum belirleyin.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('animalHouses').add({
        'animal': _selectedAnimal,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _currentAddress ?? 'Bilinmeyen adres',
        'date': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yeni ev başarıyla kaydedildi!")),
      );
      SelectedIndex.changeSelectedIndex(0);
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomePage()));
    } catch (e) {
      print("Firestore hata: $e");
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
          'Yeni Kedi/Köpek Evi Ekle',
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