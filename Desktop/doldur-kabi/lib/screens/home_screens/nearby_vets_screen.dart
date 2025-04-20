import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/screens/home_screens/vet_application_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyVetsScreen extends StatefulWidget {
  @override
  _NearbyVetsScreenState createState() => _NearbyVetsScreenState();
}

class _NearbyVetsScreenState extends State<NearbyVetsScreen> {
  bool _isSorted = true; // Default olarak en yakın başlasın
  List<Map<String, dynamic>> vets = []; // 🔥 Firestore'dan gelecek olan veriler

  @override
  void initState() {
    super.initState();
    _fetchVetsFromFirestore();
  }

  Future<void> _fetchVetsFromFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      print("🚀 Firestore'dan veterinerler çekiliyor...");

      QuerySnapshot snapshot = await firestore
          .collection('vetApplications')
          .where('status', isEqualTo: 'approved') // 🔥 Sadece onaylananları al
          .get();

      if (snapshot.docs.isEmpty) {
        print("⚠️ Firestore'da hiç onaylı veteriner bulunamadı!");
      } else {
        print("✅ ${snapshot.docs.length} tane onaylı veteriner bulundu!");
      }

      List<Map<String, dynamic>> fetchedVets = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        print("📌 Veteriner: ${data['businessName']} - ${data['address']} - ${data['phone']}");

        return {
          "name": data['businessName'] ?? "Bilinmeyen Veteriner",
          "address": data['address'] ?? "Adres belirtilmemiş",
          "phone": data['phone'] ?? "Telefon numarası yok",
        };
      }).toList();

      setState(() {
        vets = fetchedVets;
        _sortVets();
      });
    } catch (e) {
      print("❌ Firestore'dan veri çekerken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veterinerleri yüklerken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _sortVets() {
    setState(() {
      _isSorted = !_isSorted;
      vets.sort((a, b) => _isSorted ? a['name'].compareTo(b['name']) : b['name'].compareTo(a['name']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9346A1),
        title: Text(
          'Gönüllü Veterinerler',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 33),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VetApplicationScreen()),
              );
            },
          ),
        ],
      ),
      body: vets.isEmpty
          ? const Center(child: CircularProgressIndicator()) // 🔥 Veriler yüklenene kadar beklet
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filtrele:",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _sortVets,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFF9346A1), width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _isSorted ? "En Uzak" : "En Yakın",
                    style: const TextStyle(color: Color(0xFF9346A1), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: vets.length,
              itemBuilder: (context, index) {
                final vet = vets[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      vet['name'],
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      vet['address'],
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
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
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          onPressed: () async {
                            final Uri mapsUri = Uri(
                              scheme: 'https',
                              host: 'www.google.com',
                              path: '/maps/search/',
                              queryParameters: {'api': '1', 'query': vet['address']},
                            );
                            if (await canLaunchUrl(mapsUri)) {
                              await launchUrl(mapsUri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Yol tarifi açılamıyor.")),
                              );
                            }
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
