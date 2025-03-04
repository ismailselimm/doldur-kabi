import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class SupportersScreen extends StatelessWidget {
  final String accountHolder = "İSMAİL SELİM GARİP";
  final String bankName = "İş Bankası";
  final String iban = "TR540006400000111540587472";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Color(0xFF9346A1),
          title: Text(
            'Destekçilerimiz',
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
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildIbanCard(context, accountHolder, bankName, iban),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('supporters') // Firestore koleksiyon adı
                    .orderBy('date', descending: true) // En yeni destekçiler üstte olsun
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Henüz destekçi yok.",
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                      ),
                    );
                  }

                  var supporters = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: supporters.length,
                    itemBuilder: (context, index) {
                      var data = supporters[index].data() as Map<String, dynamic>;

                      return _buildSupporterCard(
                        name: data['name'] ?? "Bilinmeyen Destekçi",
                        imagePath: data['imagePath'] ?? "assets/images/avatar1.png",
                        supportAmount: data['amount'] ?? 0,
                        date: data['date'] ?? "Bilinmiyor",
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIbanCard(BuildContext context, String name, String bank, String iban) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCopyableText(context, "Ad Soyad", name),
            SizedBox(height: 12),
            _buildCopyableText(context, "Banka Adı", bank),
            SizedBox(height: 12),
            _buildCopyableText(context, "IBAN", iban),
            SizedBox(height: 8), // 🔥 Mesaj için ekstra boşluk ekledim
            Center( // 📌 Yazıyı ortalamak için buraya aldım
              child: Text(
                "Aşağıda isminizin görünmesini istemiyorsanız IBAN açıklamasında belirtiniz.",
                textAlign: TextAlign.center, // 📌 Ortalamayı kesinleştir
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomSnackbar(BuildContext context, String text) {
    final snackBar = SnackBar(
      content: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$text ✅",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildCopyableText(BuildContext context, String label, String value) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        _showCustomSnackbar(context, "$label Kopyalandı");
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ),
          const Icon(Icons.copy, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSupporterCard({
    required String name,
    required String imagePath,
    required int supportAmount,
    required String date,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(imagePath),
              radius: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Destek: ${supportAmount} TL",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Katkıda Bulundu: $date",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
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
