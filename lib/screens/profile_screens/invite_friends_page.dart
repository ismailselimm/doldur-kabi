import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class InviteFriendsPage extends StatelessWidget {
  const InviteFriendsPage({super.key});

  static const String inviteLink = 'https://www.doldurkabi.com';
  static const String inviteMessage = '''
DoldurKabı, sokak hayvanlarına yardım etmeyi kolaylaştıran sosyal bir platformdur.

• Mama kapları ve hayvan evleri ekleyerek sahadaki ihtiyaçlara destek olun.
• Kayıp hayvan ilanlarını inceleyin, bir canın bulunmasına yardımcı olun.
• Sahiplendirme ilanı oluşturun veya sahiplenerek bir hayvana yuva olun.
• Topluluk ekranında duygu ve deneyimlerinizi paylaşın.
• Acil durumları anında bildirin, hızlıca çözüm üretelim.
• Size en yakın veterinerleri harita üzerinden keşfedin.

Uygulamayı şimdi indirin:
$inviteLink
''';

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kopyalandı!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFD),
      appBar: AppBar(
        title: Text(
          'Arkadaşlarını Davet Et',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Bu yazıyı Instagram hikayende, X’te ya da WhatsApp’ta paylaşabilirsin!",
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16), // 👈 burası yuvarlama derecesi
                child: Image.asset(
                  "assets/images/logo.png",
                  height: 90,
                  width: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2FA),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                inviteMessage.trim(),
                style: GoogleFonts.poppins(fontSize: 14.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _copyText(context, inviteMessage),
              icon: const Icon(Icons.copy, size: 20, color: Colors.white),
              label: const Text("Yazıyı Kopyala",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9346A1),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteLink,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy, color: Color(0xFF9346A1)),
                    onPressed: () => _copyText(context, inviteLink),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
