import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteFriendsPage extends StatelessWidget {
  const InviteFriendsPage({super.key});

  static const String inviteLink = 'https://www.doldurkabi.com';
  static const String inviteMessage =
      'Merhaba! DoldurKabı Uygulaması ile sokak hayvanlarına umut olalım! Hemen aşağıdan indirebilirsin: $inviteLink';

  void _showInviteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Arkadaşlarını Davet Et",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        inviteLink,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.deepPurple),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Bağlantı kopyalandı!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareInvite() async {
    try {
      await MethodChannel('com.dreamly.share/share').invokeMethod('share', {
        'message': inviteMessage,
      });
    } on PlatformException catch (e) {
      print('Paylaşım yapılamadı: $e');
    }
  }

  Future<void> _shareToApp(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("❌ ERROR: Uygulama açılamadı -> $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Arkadaşlarınızı Davet Edin',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF9346A1),
        iconTheme: const IconThemeData(
          color: Colors.white, // Geri butonu ve diğer ikonlar beyaz olur
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_add_outlined,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Arkadaşlarını davet et ve eğlenceyi paylaş!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _showInviteOptions(context),
              icon: const Icon(Icons.share, color: Colors.white), // İkonu da beyaz yapalım
              label: const Text(
                'Bağlantıyı Paylaş',
                style: TextStyle(color: Colors.white), // 🔥 Yazıyı beyaz yaptım
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon("assets/images/whatsapp.png", () {
                  _shareToApp("https://api.whatsapp.com/send?text=$inviteMessage");
                }),
                const SizedBox(width: 20),
                _buildSocialIcon('assets/images/twitter.png', () {
                  _shareToApp("https://twitter.com/intent/tweet?text=$inviteMessage");
                }),
                const SizedBox(width: 20),
                _buildSocialIcon('assets/images/instagram.png', () {
                  _shareToApp("https://www.instagram.com/");
                }),
                const SizedBox(width: 20),
                _buildSocialIcon('assets/images/facebook.png', () {
                  _shareToApp("https://www.facebook.com/sharer/sharer.php?u=$inviteLink");
                }),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Nerede paylaşmak istiyorsanız, o ikona tıklayın.",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center, // Ortalamak için
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        assetPath,
        height: 50,
        width: 50,
      ),
    );
  }
}
