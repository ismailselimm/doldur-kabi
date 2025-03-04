import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  // Telefon araması yapmak için fonksiyon
  void _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorMessage(context, 'Arama yapılamadı: $phoneNumber');
    }
  }

  // Email göndermek için fonksiyon
  void _sendEmail(BuildContext context, String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query: 'subject=Destek&body=Merhaba,',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorMessage(context, 'Email gönderilemedi: $emailAddress');
    }
  }

  // Web sitesine yönlendirme
  void _launchWebsite(BuildContext context, String url) async {
    final Uri websiteUri = Uri.parse(url);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri);
    } else {
      _showErrorMessage(context, 'Web sitesine ulaşılamadı: $url');
    }
  }

  // Hata mesajlarını göstermek için yardımcı fonksiyon
  void _showErrorMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Hata', style: TextStyle(color: Colors.redAccent)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam', style: TextStyle(color: Color(0xFF9346A1))),
            ),
          ],
        );
      },
    );
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Herhangi bir sorunuz mu var? Bize ulaşın!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9346A1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildContactTile(
              context,
              icon: Icons.email,
              title: 'Email',
              subtitle: 'ismailselimgarip@gmail.com',
              onTap: () => _sendEmail(context, 'ismailselimgarip@gmail.com'),
            ),
            _buildContactTile(
              context,
              icon: Icons.language,
              title: 'Web Sitesi',
              subtitle: 'www.doldurkabi.com',
              onTap: () => _launchWebsite(context, 'https://www.doldurkabi.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Function() onTap,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9346A1).withOpacity(0.2),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: const Color(0xFF9346A1), size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
