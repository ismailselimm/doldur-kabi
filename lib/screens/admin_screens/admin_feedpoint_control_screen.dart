import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminFeedPointControlScreen extends StatefulWidget {
  const AdminFeedPointControlScreen({super.key});

  @override
  State<AdminFeedPointControlScreen> createState() => _AdminFeedPointControlScreenState();
}

class _AdminFeedPointControlScreenState extends State<AdminFeedPointControlScreen> {
  bool _isLocaleReady = false;
  String selectedAnimal = 'Tümü';

  final List<Map<String, String>> animalOptions = [
    {'value': 'Tümü', 'label': 'Tümü'},
    {'value': 'cat', 'label': 'Kedi'},
    {'value': 'dog', 'label': 'Köpek'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('tr_TR', null);
    setState(() => _isLocaleReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mama ve Hayvan Evleri', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF9346A1),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Mama Kapları"),
              Tab(text: "Hayvan Evleri"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                _buildFilterDropdown(),
                Expanded(child: _buildFeedPointList()),
              ],
            ),
            _buildAnimalHouseList(), // 👈 Yeni sekme burada
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalHouseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('animalHouses')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;

        final pendingApproval = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isApproved'] == false;
        }).toList();

        final approved = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isApproved'] == true;
        }).toList();

        if (allDocs.isEmpty) {
          return const Center(child: Text("Hayvan evi bulunamadı."));
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (pendingApproval.isNotEmpty) ...[
              const Text("🕓 Onay Bekleyenler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...pendingApproval.map((doc) => _buildHouseCard(doc, true)).toList(),
              const Divider(),
            ],
            if (approved.isNotEmpty) ...[
              const Text("✅ Onaylanmışlar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...approved.map((doc) => _buildHouseCard(doc, false)).toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHouseCard(DocumentSnapshot doc, bool showApproveButton) {
    final data = doc.data() as Map<String, dynamic>;

    final address = data['address'] ?? 'Adres yok';
    final animal = _translateAnimal(data['animal'] ?? 'Bilinmiyor');
    final imageUrl = data['imageUrl'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: ListTile(
        leading: imageUrl != null
            ? GestureDetector(
          onTap: () => _showFullImage(context, imageUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
          ),
        )
            : const Icon(Icons.home_work, size: 40),
        title: Text(address, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text("Hayvan Türü: $animal", style: GoogleFonts.poppins(fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showApproveButton)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _approveHouse(doc.reference),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, doc.reference),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveHouse(DocumentReference ref) async {
    await ref.update({'isApproved': true});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hayvan evi onaylandı")),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DropdownButton<String>(
        value: selectedAnimal,
        onChanged: (value) => setState(() => selectedAnimal = value!),
        items: animalOptions.map((animal) {
          return DropdownMenuItem(
            value: animal['value'],
            child: Text("Hayvan: ${animal['label']}"),
          );
        }).toList(),
      )
    );
  }

  Widget _buildFeedPointList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedPoints')
          .orderBy('lastFilled', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final feedPoints = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final animal = data['animal'] ?? '';
          if (selectedAnimal != 'Tümü' && animal != selectedAnimal) return false;
          return true;
        }).toList();

        if (feedPoints.isEmpty) {
          return const Center(child: Text("Mama kabı bulunamadı."));
        }

        return ListView.builder(
          itemCount: feedPoints.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final doc = feedPoints[index];
            final data = doc.data() as Map<String, dynamic>;

            final address = data['address'] ?? 'Adres yok';
            final animalRaw = data['animal'] ?? 'Bilinmiyor';
            final animal = _translateAnimal(animalRaw);
            final lastFilled = data['lastFilled'] != null
                ? _formatDateTime((data['lastFilled'] as Timestamp).toDate())
                : 'Bilinmiyor';
            final imageUrl = data['lastFilledImageUrl'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 6,
              child: ListTile(
                leading: imageUrl != null && imageUrl.toString().isNotEmpty
                    ? GestureDetector(
                  onTap: () => _showFullImage(context, imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    : const FaIcon(FontAwesomeIcons.utensils, color: Colors.orange),
                title: Text(address, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hayvan Türü: $animal", style: GoogleFonts.poppins(fontSize: 13)),
                    Text("Son Doldurma: $lastFilled", style: GoogleFonts.poppins(fontSize: 13)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, doc.reference),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  String _translateAnimal(String type) {
    switch (type) {
      case 'cat':
        return 'Kedi';
      case 'dog':
        return 'Köpek';
      default:
        return 'Bilinmiyor';
    }
  }

  void _confirmDelete(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Mama Kabını Sil"),
        content: const Text("Bu mama kabını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(child: const Text("İptal"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await ref.delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mama kabı silindi")),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('d MMMM yyyy – HH:mm', 'tr_TR');
    return formatter.format(dateTime);
  }
}
