import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/home_screens/vet_application_screen.dart';
import 'package:doldur_kabi/screens/home_screens/volunteer_vets_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';


class NearbyVetsScreen extends StatefulWidget {
  @override
  _NearbyVetsScreenState createState() => _NearbyVetsScreenState();
}

class _NearbyVetsScreenState extends State<NearbyVetsScreen> {
  bool _isSorted = true;
  List<Map<String, dynamic>> vets = [];

  @override
  void initState() {
    super.initState();
    _fetchVetsFromFirestore();
  }

  Future<void> _fetchVetsFromFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Konum izni
      Position userPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      QuerySnapshot snapshot = await firestore
          .collection('vetApplications')
          .where('status', isEqualTo: 'approved')
          .get();

      List<Map<String, dynamic>> fetchedVets = snapshot.docs
          .where((doc) =>
      (doc.data() as Map<String, dynamic>).containsKey('latitude') &&
          (doc.data() as Map<String, dynamic>).containsKey('longitude'))
          .map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        double vetLat = data['latitude'];
        double vetLng = data['longitude'];
        double distanceInMeters = Geolocator.distanceBetween(
          userPos.latitude,
          userPos.longitude,
          vetLat,
          vetLng,
        );

        return {
          "name": data['businessName'] ?? "Bilinmeyen Veteriner",
          "address": data['address'] ?? "Adres belirtilmemiş",
          "phone": data['phone'] ?? "Telefon numarası yok",
          "latitude": data['latitude'],
          "longitude": data['longitude'],
          "distance": distanceInMeters,
          "support": data['supportDescription'] ?? "",
        };


      }).toList();

      // Başlangıçta en yakına göre sırala
      fetchedVets.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        vets = fetchedVets;
        _isSorted = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veterinerleri yüklerken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> openMapsWithQuery(String address) async {
    final String query = Uri.encodeComponent(address);
    final Uri mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (!await launchUrl(mapsUrl, mode: LaunchMode.externalApplication)) {
      throw '❌ Harita açılamadı: $mapsUrl';
    }
  }


  void _openMaps(double latitude, double longitude) async {
    final googleMapsUrl = Uri.parse("comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving");
    final appleMapsUrl = Uri.parse("https://maps.apple.com/?daddr=$latitude,$longitude");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konum açılamıyor.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9346A1),
        title: Text(
          'Veterinerler',
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
            icon: const FaIcon(
              FontAwesomeIcons.mapLocationDot,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VolunteerVetsMapScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VetApplicationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: vets.isEmpty
          ? const Center(child: Text("Henüz gönüllü veteriner bulunamadı."))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              "📍 Veterinerler konumunuza göre en yakından uzağa sıralanmıştır.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: vets.length,
              itemBuilder: (context, index) {
                final vet = vets[index];
                return Card(
                  margin: const EdgeInsets.all(12.0),
                  child: ListTile(
                    title: Text(
                      vet['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vet['address'],
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        if (vet['support'] != null && vet['support'].toString().trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "🎁",
                                  style: TextStyle(fontSize: 22), // Büyük emoji
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vet['support'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),


                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.black),
                          onPressed: () async {
                            final Uri phoneUri = Uri(scheme: 'tel', path: vet['phone']);
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Telefon araması başlatılamıyor.")),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.directions, color: Colors.purple),
                          onPressed: () {
                            _openMaps(vet['latitude'], vet['longitude']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}