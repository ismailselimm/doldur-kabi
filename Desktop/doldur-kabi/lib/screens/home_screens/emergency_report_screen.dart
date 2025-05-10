import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              leading: const Icon(Icons.camera_alt, color: Colors.redAccent),
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
              leading: const Icon(Icons.photo, color: Colors.purple),
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
      setState(() {
        _selectedLocation = current;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(current, 16));
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

  // En üstte importlar aynı kalsın

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
            Text("Durum Sebebi",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration(),
              value: _selectedReason,
              items: _reasons
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedReason = val),
            ),
            const SizedBox(height: 20),
            Text("Açıklama",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration:
                  _inputDecoration(hint: "Durumu detaylı şekilde açıklayın..."),
            ),
            const SizedBox(height: 20),
            Text("Fotoğraf",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                height: 120,
                child: _selectedImages.isEmpty
                    ? const Center(
                        child: Icon(Icons.add_photo_alternate,
                            size: 40, color: Colors.grey))
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
                                    decoration: BoxDecoration(
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
            const SizedBox(height: 20),
            Text("Konum",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_address != null)
              Text("📍 $_address", style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 6),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        _selectedLocation ?? const LatLng(39.925533, 32.866287),
                    zoom: 14,
                  ),
                  onMapCreated: (c) => _mapController = c,
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
                  if (_selectedLocation == null || _selectedReason == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Lütfen konum ve durum bilgisini girin."),
                      ),
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);

                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final now = Timestamp.now();

                    // 🔹 1. Fotoğrafları yükle
                    List<String> imageUrls = [];
                    for (File image in _selectedImages) {
                      try {
                        if (!await image.exists()) {
                          debugPrint("⚠️ Dosya bulunamadı, yüklenemiyor.");
                          continue;
                        }

                        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(image)}.jpg';
                        final ref = FirebaseStorage.instance
                            .ref()
                            .child('emergency_reports')
                            .child(fileName);

                        final bytes = await image.readAsBytes();
                        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
                        final url = await ref.getDownloadURL();


                        imageUrls.add(url);
                      } catch (e) {
                        debugPrint("🔥 Yükleme hatası: $e");
                        debugPrint("🔥🔥 TAM HATA: ${e.toString()}");
                        debugPrint("Yüklenen dosya path: ${image.path}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("📷 Fotoğraf yüklenemedi: $e")),

                        );
                      }
                    }


                    // 🔹 2. Firestore’a veriyi kaydet
                    await FirebaseFirestore.instance
                        .collection('emergency_reports')
                        .add({
                      'userId': uid,
                      'reason': _selectedReason,
                      'description': _descriptionController.text.trim(),
                      'latitude': _selectedLocation!.latitude,
                      'longitude': _selectedLocation!.longitude,
                      'address': _address ?? 'Bilinmiyor',
                      'images': imageUrls,
                      'timestamp': now,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        duration: const Duration(seconds: 3),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Acil durum başarıyla bildirildi!",
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );


                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Hata oluştu: $e")),
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

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }


}
