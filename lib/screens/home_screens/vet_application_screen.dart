import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VetApplicationScreen extends StatefulWidget {
  @override
  _VetApplicationScreenState createState() => _VetApplicationScreenState();
}

class _VetApplicationScreenState extends State<VetApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _supportController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isVolunteer = false;
  bool _isSubmitting = false;

  LatLng? _selectedLocation;
  String? _autoAddress;
  GoogleMapController? _mapController;

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun ve konum seçin.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('vetApplications').add({
        'businessName': _nameController.text,
        'address': _autoAddress ?? "Adres alınamadı",
        'phone': _phoneController.text,
        'isVolunteer': _isVolunteer,
        'supportDescription': _supportController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("Başvuru Alındı"),
            ],
          ),
          content: const Text("Veteriner başvurunuz başarıyla kaydedildi."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Tamam"),
            )
          ],
        ),
      );
    } catch (e) {
      print("❌ Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hata oluştu. Lütfen tekrar deneyin.")),
      );
    }

    setState(() => _isSubmitting = false);
  }

  void _onMapTap(LatLng location) {
    setState(() => _selectedLocation = location);
    _getAddressFromLatLng(location.latitude, location.longitude);
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _autoAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
          _addressController.text = _autoAddress!; // 👈 adres alanına da yaz
        });
      }
    } catch (e) {
      setState(() {
        _autoAddress = "Adres alınamadı";
        _addressController.text = "Adres alınamadı";
      });
    }
  }

  Future<void> _getUserLocationAndMoveCamera() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = userLatLng;
      });

      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: 15),
      ));

      _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      print("📍 Konum alınamadı: $e");
    }
  }

  void _geocodeAddressAndMoveMap() async {
    try {
      String updatedAddress = _addressController.text;
      List<Location> locations = await locationFromAddress(updatedAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _selectedLocation = latLng;
          _autoAddress = updatedAddress;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Girdiğiniz adres konuma çevrilemedi.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Veteriner Başvurusu',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            )),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
                 DefaultTextStyle(
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  child: AnimatedTextKit(
                    isRepeatingAnimation: true,
                    totalRepeatCount: 99,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        '  Birlikte daha fazla can kurtarabiliriz...',
                        speed: const Duration(milliseconds: 75),
                        cursor: '|',
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              _buildTextField("İşletme İsmi", _nameController, Icons.business),
              const SizedBox(height: 15),
              _buildTextField("Telefon Numarası", _phoneController, Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 15),
              TextFormField(
                controller: _supportController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Sağlayabileceğiniz Destek",
                  hintText: "Örn: DoldurKabı Üyelerine özel %20 indirim, Sokak hayvanı getirenlere %50 indirim...",
                  prefixIcon: const Icon(Icons.volunteer_activism, color: Colors.purple),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Haritadan Konum Seçin:",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _getUserLocationAndMoveCamera(); // 🔥 BURAYI EKLE
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(41.0082, 28.9784), // fallback (örnek: İstanbul)
                      zoom: 13,
                    ),
                    onTap: _onMapTap,
                    markers: _selectedLocation != null
                        ? {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: _selectedLocation!,
                      )
                    }
                        : {},
                    zoomControlsEnabled: false,
                    myLocationEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_autoAddress != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // 👈 dıştan daralttık
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: TextFormField(
                        controller: _addressController,
                        onEditingComplete: _geocodeAddressAndMoveMap,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),

              CheckboxListTile(
                title: Text("Gönüllü olarak başvuruyorum", style: GoogleFonts.poppins(fontSize: 16)),
                value: _isVolunteer,
                onChanged: (bool? value) {
                  setState(() {
                    _isVolunteer = value!;
                  });
                },
                activeColor: const Color(0xFF9346A1),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _isVolunteer && !_isSubmitting ? _submitApplication : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVolunteer ? Colors.purple[700] : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Başvuruyu Gönder", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bu alan zorunludur';
        }
        if (label == "Telefon Numarası" && (value.length < 10 || value.length > 13)) {
          return 'Geçerli bir telefon numarası girin';
        }
        return null;
      },
    );
  }
}
