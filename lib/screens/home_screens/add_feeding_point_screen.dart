import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../main.dart';
import '../login_screens/login_screen.dart';
import 'package:doldur_kabi/screens/home_screens/main_home_page.dart';

class AddFeedingPointScreen extends StatefulWidget {
  @override
  _AddFeedingPointScreenState createState() => _AddFeedingPointScreenState();
}

class _AddFeedingPointScreenState extends State<AddFeedingPointScreen> {
  String? _selectedAnimal;
  Position? _currentPosition;
  String? _currentAddress;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = false;


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
            "Besleme Noktası Ekleme",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[700]),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Besleme noktası ekleyebilmek için giriş yapmalısınız.",
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


  Future<void> _saveFeedingPoint() async {
    if (_selectedAnimal == null || _selectedLocation == null) {
      showModernSnackbar(
        context,
        "Lütfen hayvan türü seçin ve bir konum belirleyin.",
        isError: true,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('feedPoints').add({
        'animal': _selectedAnimal,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _currentAddress ?? 'Bilinmeyen adres',
        'date': DateTime.now(),
        'addedBy': FirebaseAuth.instance.currentUser!.uid,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'beslemeNoktasiSayisi': FieldValue.increment(1)});

      showModernSnackbar(context, "Besleme noktası başarıyla kaydedildi!");
      SelectedIndex.changeSelectedIndex(0);
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      print("❌ Firestore hata: $e");
      showModernSnackbar(context, "Kayıt sırasında bir hata oluştu, tekrar deneyin.", isError: true);
    }
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
        const SnackBar(content: Text("Konum alınamadı. Lütfen konum servislerini kontrol edin.")),
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
          'Yeni Besleme Kabı Ekle',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Hayvan Türünü Seçin:", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimalOption("Kedi", "assets/images/cat.png", "cat"),
                _buildAnimalOption("Köpek", "assets/images/dog.png", "dog"),
              ],
            ),
            const SizedBox(height: 5),
            if (_currentAddress != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "📍Adres : $_currentAddress",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF9346A1), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
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
            const SizedBox(height: 20),
            Text(
              "Ekleyeceğiniz konumu harita üzerinden istediğiniz noktaya basarak seçiniz."
                  " Kabı ekledikten sonra ana sayfadan doldurmayı unutmayınız! 😇",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _selectedLocation == null ? null : _saveFeedingPoint,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23B14D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
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

      backgroundColor: const Color(0xFFF8F8F8),
    );
  }

  void showCustomSnackbar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: SlideInSnackbar(message: message),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void showModernSnackbar(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 20,
        right: 20,
        child: SlideUpSnackbar(message: message, isError: isError),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
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
}


class SlideUpSnackbar extends StatefulWidget {
  final String message;
  final bool isError;

  const SlideUpSnackbar({super.key, required this.message, this.isError = false});

  @override
  State<SlideUpSnackbar> createState() => _SlideUpSnackbarState();
}

class _SlideUpSnackbarState extends State<SlideUpSnackbar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, -0.02),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      _controller.reverse().then((_) {
        if (mounted) Navigator.of(context).overlay?.dispose();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: widget.isError
                          ? [Colors.redAccent.shade200, Colors.red.shade400]
                          : [const Color(0xFF1BC47D), const Color(0xFF15935B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            decoration: TextDecoration.none, // ✅ ALT ÇİZGİYİ TAMAMEN KALDIRIR
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class SlideInSnackbar extends StatefulWidget {
  final String message;
  const SlideInSnackbar({super.key, required this.message});

  @override
  State<SlideInSnackbar> createState() => _SlideInSnackbarState();
}

class _SlideInSnackbarState extends State<SlideInSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        color: Colors.green.shade600,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


