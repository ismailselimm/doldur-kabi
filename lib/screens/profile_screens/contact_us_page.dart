import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  String _secilenTur = 'Öneri';
  final TextEditingController _mesajController = TextEditingController();

  Future<void> _mesajGonder() async {
    final mesaj = _mesajController.text.trim();
    if (mesaj.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'type': _secilenTur, // Bu zaten "Öneri" veya "Şikayet"
        'message': mesaj,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid ?? 'anonim',
        'userEmail': user?.email ?? 'anonim',
        'userDisplayName': user?.displayName ?? 'Bilinmiyor',
      });

      _mesajController.clear();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Gönderildi ✅"),
          content: const Text("Bizle iletişime geçtiğiniz teşekkür ederiz 💜"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("🔥 Firebase Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir hata oluştu, lütfen tekrar deneyin.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bize Ulaşın',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Görüş ve düşünceleriniz bizim için değerli. 💜',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9346A1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Öneri / Şikayet seçim
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Öneri"),
                  selected: _secilenTur == "Öneri",
                  onSelected: (_) => setState(() => _secilenTur = "Öneri"),
                  selectedColor: Colors.green.shade200,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text("Şikayet"),
                  selected: _secilenTur == "Şikayet",
                  onSelected: (_) => setState(() => _secilenTur = "Şikayet"),
                  selectedColor: Colors.red.shade200,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Text Area
            TextField(
              controller: _mesajController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Mesajınızı buraya yazın...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Gönder butonu
            ElevatedButton(
              onPressed: _mesajGonder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9346A1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Gönder",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),

            const SizedBox(height: 30),
            Text(
              "veya",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),


            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, color: Color(0xFF9346A1)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse('mailto:ismailselimgarip@gmail.com'));
                    },
                    child: Text(
                      "ismailselimgarip@gmail.com",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9346A1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Mail butonuna dokunabilirsiniz. ⬆️",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),


          ],
        ),
      ),
    );
  }
}
