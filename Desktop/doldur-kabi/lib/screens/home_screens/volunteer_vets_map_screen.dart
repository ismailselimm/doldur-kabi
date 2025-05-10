import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/functions/get_resized_marker.dart';
import 'package:doldur_kabi/screens/home_screens/vet_application_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerVetsMapScreen extends StatefulWidget {
  const VolunteerVetsMapScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerVetsMapScreen> createState() => _VolunteerVetsMapScreenState();
}

class _VolunteerVetsMapScreenState extends State<VolunteerVetsMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _vetIcon;
  BitmapDescriptor? _personIcon;
  LatLng? _selectedVetPosition;
  Map<String, dynamic>? _selectedVetData;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  LatLng offsetLatLng(LatLng original, int index) {
    const double offsetDistance = 0.00006;
    double dx = offsetDistance * (index % 3 - 1);
    double dy = offsetDistance * ((index ~/ 3) - 1);
    return LatLng(original.latitude + dy, original.longitude + dx);
  }

  Future<void> _initializeMap() async {
    await _loadIcons();
    await _getCurrentLocation();
    await _loadVolunteerVets();
  }

  Future<void> openMapsWithQuery(String address) async {
    final String query = Uri.encodeComponent(address);
    final Uri mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (!await launchUrl(mapsUrl, mode: LaunchMode.externalApplication)) {
      throw '❌ Harita açılamadı: $mapsUrl';
    }
  }

  Future<void> _loadIcons() async {
    _personIcon = await getResizedMarker("assets/images/person5.png", 135, 135);
    _vetIcon = await getResizedMarker("assets/images/veterinary.png", 130, 130);
  }

  Future<void> _getCurrentLocation({bool animate = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      _currentPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == "current_location");
        _markers.add(
          Marker(
            markerId: const MarkerId("current_location"),
            position: _currentPosition!,
            icon: _personIcon!,
            infoWindow: const InfoWindow(title: "Mevcut Konum"),
          ),
        );
      });

      if (animate) {
        _mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 15.0),
        ));
      }
    }
  }

  Future<void> _loadVolunteerVets() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vetApplications')
        .where('status', isEqualTo: 'approved')
        .where('isVolunteer', isEqualTo: true)
        .get();

    int index = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      LatLng? position;

      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        position = LatLng(data['latitude'], data['longitude']);
      } else if (data.containsKey('address')) {
        try {
          List<Location> locations = await locationFromAddress(data['address']);
          if (locations.isNotEmpty) {
            position = LatLng(locations.first.latitude, locations.first.longitude);
          }
        } catch (e) {
          print("❌ Geocode hatası: ${data['address']} - $e");
        }
      }

      if (position != null) {
        LatLng adjustedPosition = offsetLatLng(position, index);
        index++;

        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: adjustedPosition,
            icon: _vetIcon!,
            onTap: () {
              setState(() {
                final LatLng pos = adjustedPosition; // 🔥 BURASI DEĞİŞTİ!
                _selectedVetPosition = adjustedPosition;
                _selectedVetData = data;
              });

              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: adjustedPosition, zoom: 17),
                ),
              );
            },
          ),
        );
      }
    }

    setState(() {});
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harita yönlendirmesi açılamadı.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9346A1),
        title: Text(
          'Veteriner Haritası',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VetApplicationScreen()));
            },
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
        onTap: () {
          setState(() {
            _selectedVetPosition = null;
            _selectedVetData = null;
          });
        },
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 13),
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onTap: (_) {
                setState(() {
                  _selectedVetPosition = null;
                  _selectedVetData = null;
                });
              },
            ),

            // 🔥 VETERİNER BİLGİ KUTUSU
            if (_selectedVetPosition != null && _selectedVetData != null)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 140,
                top: MediaQuery.of(context).size.height / 2 - 40,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVetData!['businessName'] ?? 'Veteriner',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedVetData!['address'] ?? 'Adres bulunamadı',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final address = _selectedVetData?['address'] ?? '';
                          openMapsWithQuery(address);
                        },




                        child: Row(
                          children: const [
                            Icon(Icons.navigation, color: Colors.purple, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "Yol Tarifi Al",
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),




                      ),
                    ],
                  ),
                ),
              ),

            // 🔍 ZOOM ve KONUM
            Positioned(
              bottom: 100,
              right: 10,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: "zoomIn",
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    heroTag: "zoomOut",
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                    child: const Icon(Icons.remove, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    heroTag: "goToLocation",
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _getCurrentLocation(animate: true);
                    },
                    child: const Icon(Icons.my_location, color: Colors.purple),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
