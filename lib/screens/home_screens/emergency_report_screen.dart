import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login_screens/login_screen.dart';

class EmergencyReportScreen extends StatefulWidget {
  const EmergencyReportScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  String? _selectedReason =
      'Yaralı hayvan bildirimi'; // 👈 direkt başta atanıyor
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _selectedImages = [];
  LatLng? _selectedLocation;
  String? _address;
  GoogleMapController? _mapController;
  bool _isSubmitting = false;
  final user = FirebaseAuth.instance.currentUser;



  final List<String> _reasons = [
    'Yaralı hayvan bildirimi',
    'Ölü hayvan bildirimi',
    'Saldırgan hayvan tehlikesi',
    'Kaybolmuş hayvan',
    'Barınak dışında yavru bulunması',
    'Hayvana şiddet/ihmal',
    'Diğer',
  ];

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Wrap(
          children: [
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.cameraRetro,
                color: Colors.black87,
                size: 22,
              ),
              title: const Text("Kameradan Çek"),
              onTap: () async {
                final picked =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() {
                    _selectedImages.add(File(picked.path));
                  });
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.image,
                color: Colors.black,
                size: 22,
              ),
              title: const Text("Galeriden Seç"),
              onTap: () async {
                final picked =
                    await ImagePicker().pickMultiImage(); // 👈 Çoklu seçim
                if (picked.isNotEmpty) {
                  setState(() {
                    _selectedImages.addAll(picked.map((x) => File(x.path)));
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLatLng(location.latitude, location.longitude);
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.country
          ].where((element) => element != null && element!.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _address = "Adres alınamadı";
      });
    }
  }


  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng current = LatLng(position.latitude, position.longitude);

      // Önce location'ı ata
      setState(() {
        _selectedLocation = current;
      });

      // Sonra haritayı oynat
      if (_mapController != null) {
        _mapController!.animateCamera( CameraUpdate.newLatLngZoom(current, 16));
      }

      // Adres çek
      _getAddressFromLatLng(current.latitude, current.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konum alınamadı.")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Acil Durum Bildir',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user == null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.redAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(
                              text: "Formu gönderebilmek için lütfen önce giriş yapın. "
                                  "Bu adım, asılsız ihbarlara karşı alınan bir önlemdir. ",
                            ),
                            TextSpan(
                              text: "Buraya tıklayarak giriş yapabilirsiniz.",
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text("Durum Sebebi", style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),

            const SizedBox(height: 6),

            _buildReasonSelector(),

            const SizedBox(height: 20),
            Text("Açıklama",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Durumu detaylı şekilde açıklayınız...",
                  border: InputBorder.none, // 👈 iç çerçeveyi kaldırıyoruz
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Fotoğraf Seç",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      height: 120,
                      width: 400,
                      child: _selectedImages.isEmpty
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate,
                              size: 40, color: Colors.grey),
                          SizedBox(height: 6),
                          Text(
                            "Buraya dokunarak fotoğraf ekleyebilirsiniz",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                          : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 20, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "📍Konum ",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: "\n(Harita üzerinden işaretleyerek seçebilirsiniz.)",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey, // Daha açık renkli
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (_address != null)
              Text("$_address", style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 6),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? const LatLng(0, 0), // veya dummy (0,0)
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
                      );
                    }
                  },
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId("selected"),
                            position: _selectedLocation!,
                          )
                        }
                      : {},
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : ElevatedButton.icon(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    _showSnackBar(
                      context,
                      "Acil durum bildirebilmek için önce giriş yapmanız gerekiyor.",
                      Colors.redAccent,
                    );
                    return;
                  }

                  if (_selectedLocation == null || _selectedReason == null) {
                    _showSnackBar(
                      context,
                      "Lütfen konum ve durum bilgisini girin.",
                      Colors.redAccent,
                    );
                    return;
                  }

                  if (_selectedImages.isEmpty) {
                    _showSnackBar(
                      context,
                      "Lütfen en az bir fotoğraf ekleyin.",
                      Colors.orangeAccent,
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);

                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final now = Timestamp.now();

                    // 🔹 Fotoğrafları yükle
                    List<String> imageUrls = [];
                    for (File image in _selectedImages) {
                      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(image)}.jpg';
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('emergency_photos')
                          .child(fileName);

                      final bytes = await image.readAsBytes();
                      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
                      final url = await ref.getDownloadURL();
                      imageUrls.add(url);
                    }

                    // 🔹 Firestore'a kayıt
                    await FirebaseFirestore.instance.collection('emergency_reports').add({
                      'userId': uid,
                      'reason': _selectedReason,
                      'description': _descriptionController.text.trim(),
                      'latitude': _selectedLocation!.latitude,
                      'longitude': _selectedLocation!.longitude,
                      'address': _address ?? 'Bilinmiyor',
                      'images': imageUrls,
                      'timestamp': now,
                    });

                    _showSnackBar(
                      context,
                      "Acil durumu bildirdiğiniz için teşekkür ederiz.",
                      Colors.green,
                      icon: Icons.check_circle_outline,
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    _showSnackBar(
                      context,
                      "❌ Hata oluştu: $e",
                      Colors.red,
                    );
                  } finally {
                    setState(() => _isSubmitting = false);
                  }
                },
                label: const Text(
                  "Bildir",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 8,
                  shadowColor: Colors.redAccent.shade100,
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildReasonSelector() {
    return GestureDetector(
      onTap: () => _showReasonPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedReason ?? "Durum Seçiniz",
                style: GoogleFonts.poppins(fontSize: 15.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }


  void _showReasonPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            shrinkWrap: true,
            children: _reasons.map((reason) {
              final isSelected = reason == _selectedReason;
              return ListTile(
                title: Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.redAccent : Colors.black,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.redAccent)
                    : null,
                onTap: () {
                  setState(() => _selectedReason = reason);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }



  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }


}
