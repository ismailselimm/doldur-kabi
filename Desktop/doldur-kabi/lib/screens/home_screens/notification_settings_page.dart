import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool appNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bildirim Ayarları',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _buildNotificationCard(
              icon: Icons.notifications_active,
              title: 'Uygulama Bildirimleri',
              subtitle: 'Yeni içerik ve aktiviteler hakkında bildirimler al',
              value: appNotifications,
              onChanged: (bool value) {
                setState(() {
                  appNotifications = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              icon: Icons.email_outlined,
              title: 'E-posta Bildirimleri',
              subtitle: 'Yeni bildirimler ve güncellemeler hakkında e-posta al',
              value: emailNotifications,
              onChanged: (bool value) {
                setState(() {
                  emailNotifications = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              icon: Icons.sms_outlined,
              title: 'SMS Bildirimleri',
              subtitle: 'Kritik bildirimler hakkında SMS al',
              value: smsNotifications,
              onChanged: (bool value) {
                setState(() {
                  smsNotifications = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF9346A1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 28, color: const Color(0xFF943EA5)),
            ),
            const SizedBox(width: 16),
            Expanded(  // !!! Burası Eklendi
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF9346A1),
            ),
          ],
        ),
      ),
    );
  }
}
