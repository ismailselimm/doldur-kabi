import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../login_screens/login_screen.dart';
import 'package:doldur_kabi/screens/home_screens/main_home_page.dart';


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
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;




  @override
  void initState() {
    super.initState();
    _checkUserLoginStatus();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
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
      showModernSnackbar(context, "Lütfen hayvan türü seçin ve bir konum belirleyin.", isError: true);
      return;
    }

    if (_selectedImage == null) {
      showModernSnackbar(context, "Lütfen bir fotoğraf seçin.", isError: true);
      return;
    }

    setState(() => _isLoading = true); // ⏳ animasyon başlasın

    try {
      String? imageUrl;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('animal_house_images/$fileName');
      final bytes = await _selectedImage!.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('animalHouses').add({
        'animal': _selectedAnimal,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _currentAddress ?? 'Bilinmeyen adres',
        'date': DateTime.now(),
        'addedBy': FirebaseAuth.instance.currentUser!.uid,
        'imageUrl': imageUrl,
        'isApproved': false, // 🔥 Yeni alan

      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'hayvanEviSayisi': FieldValue.increment(1)});

      showModernSnackbar(context, "Yeni hayvan evi başarıyla kaydedildi, onaylandıktan sonra görünecektir!");
      SelectedIndex.changeSelectedIndex(0);
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      print("❌ Firestore hata: $e");
      showModernSnackbar(context, "Kayıt sırasında bir hata oluştu, tekrar deneyin.", isError: true);
    } finally {
      setState(() => _isLoading = false);
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
            child: Image.asset(imagePath, width: 50, height: 50),
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

      // Haritayı merkeze al
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 17,
            ),
          ),
        );
      }

      _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      showModernSnackbar(context, "Konum alınamadı. Lütfen konum servislerini kontrol edin.", isError: true);
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
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // 👈 kaydırma kapalı
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
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF9346A1), width: 3),
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
                      : const CameraPosition(target: LatLng(37.7749, -122.4194), zoom: 15),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 17));
                    }
                  },
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {Marker(markerId: const MarkerId("selected"), position: _selectedLocation!)}
                      : {},
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
                "Ekleyeceğiniz konumu harita üzerinden istediğiniz noktaya basarak seçiniz. Aşağıdan"
                    " hayvan evinin fotoğrafını eklemeyi unutmayın!  😇",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.image, size: 40, color: Colors.grey[600]),
                    const SizedBox(height: 10),
                    Text(
                      "Fotoğraf seçmek için tıklayın",
                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ],
                )
                    : Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        width: 110,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Yüklenen fotoğraf",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedLocation == null || _isLoading ? null : _saveAnimalHouse,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23B14D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
                  : Text(
                "Kaydet",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
    );
  }

  void showModernSnackbar(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 70,
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


}

class SlideUpSnackbar extends StatefulWidget {
  final String message;
  final bool isError;
  const SlideUpSnackbar({super.key, required this.message, this.isError = false});

  @override
  _SlideUpSnackbarState createState() => _SlideUpSnackbarState();
}

class _SlideUpSnackbarState extends State<SlideUpSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      position: _offsetAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isError ? Colors.redAccent : Colors.green[600],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            children: [
              Icon(
                widget.isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
              ),
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
