import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminFeedbackControlScreen extends StatefulWidget {
  const AdminFeedbackControlScreen({super.key});

  @override
  State<AdminFeedbackControlScreen> createState() => _AdminFeedbackControlScreenState();
}

class _AdminFeedbackControlScreenState extends State<AdminFeedbackControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F9),
      appBar: AppBar(
        title: Text(
          'Öneri ve Şikayetler',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Öneriler'),
            Tab(text: 'Şikayetler'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedbackList("Öneri"),
          _buildFeedbackList("Şikayet"),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(String type) {
    final isComplaintTab = type == "Şikayet";

    if (!isComplaintTab) {
      // Sadece Öneriler (feedbacks koleksiyonundan)
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .where('type', isEqualTo: type)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Henüz hiç $type bulunmuyor.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final mesaj = data['message'] ?? '';
              final kullanici = data['userDisplayName'] ?? 'Bilinmiyor';
              final email = data['userEmail'] ?? 'Gizli';
              final zaman = (data['timestamp'] as Timestamp?)?.toDate();

              return _buildCard(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kullanici,
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 4),
                    Text(email, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    Text(mesaj, style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87)),
                    if (zaman != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          _formatDate(zaman),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                        ),
                      )
                    ]
                  ],
                ),
              );
            },
          );
        },
      );
    }

    // Şikayetler: Hem feedbacks hem complaints
    final feedbacksFuture = FirebaseFirestore.instance
        .collection('feedbacks')
        .where('type', isEqualTo: 'Şikayet')
        .get();
    final complaintsFuture = FirebaseFirestore.instance.collection('complaints').get();

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([feedbacksFuture, complaintsFuture]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final feedbackDocs = snapshot.data![0].docs;
        final complaintDocs = snapshot.data![1].docs;
        final allDocs = [...feedbackDocs, ...complaintDocs];

        allDocs.sort((a, b) {
          final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });

        if (allDocs.isEmpty) {
          return Center(
            child: Text(
              'Henüz hiç şikayet bulunmuyor.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allDocs.length,
          itemBuilder: (context, index) {
            final data = allDocs[index].data() as Map<String, dynamic>;
            final zaman = (data['timestamp'] as Timestamp?)?.toDate();
            final isFromComplaint = data.containsKey('contentId');

            return _buildCard(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFromComplaint) ...[
                    _buildRow("Tür", data['type'] ?? '-'),
                    _buildRow("Sebep", data['reason'] ?? '-'),
                    _buildRow("Bildiren", data['reportedBy'] ?? '-'),
                  ] else ...[
                    Text(data['userDisplayName'] ?? "Bilinmeyen Kullanıcı",
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 4),
                    Text(data['userEmail'] ?? "Gizli",
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    Text(data['message'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87)),
                  ],
                  if (zaman != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatDate(zaman),
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                      ),
                    )
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
