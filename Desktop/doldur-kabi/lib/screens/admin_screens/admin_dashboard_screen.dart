import 'package:doldur_kabi/screens/admin_screens/admin_ad_control_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/admin_feedpoint_control_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/admin_post_control_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/admin_vet_applications_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/reports_screen.dart';
import 'package:doldur_kabi/screens/admin_screens/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'admin_complaints_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_send_notification_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Admin Paneli',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardItem(
              icon: FontAwesomeIcons.utensils,
              label: 'Mama Kabı Kontrol',
              color: Colors.lightGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminFeedPointControlScreen()),
                );
              },
            ),
            _buildDashboardItem(
              icon: FontAwesomeIcons.paperPlane,
              label: 'Gönderi Kontrol',
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPostControlScreen()),
                );
              },
            ),
            _buildDashboardItem(
              icon: FontAwesomeIcons.bullhorn,
              label: 'İlan Kontrol',
              color: Colors.pinkAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminAdControlScreen()),
                );
              },
            ),
            _buildDashboardItem(
              icon: FontAwesomeIcons.users,
              label: 'Kullanıcılar',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminUsersScreen()),
                );
              },
            ),
            _buildDashboardItem(
              icon: FontAwesomeIcons.commentDots, // 💬 Daha uygun ve havalı bir ikon
              label: 'Öneri / Şikayetler',
              color: Colors.deepOrangeAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminFeedbackControlScreen()),
                );
              },
            ),
            _buildDashboardItem(
              icon: FontAwesomeIcons.userDoctor,
              label: 'Veteriner Onay',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminVetApplicationsScreen()),
                );
              },
            ),
            _buildDashboardItem(
              icon: FontAwesomeIcons.bell,
              label: 'Bildirim Gönder',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminSendNotificationScreen()),
                );
              },
            ),
            _buildDashboardItem(
              icon: FontAwesomeIcons.chartLine,
              label: 'Raporlar',
              color: Colors.deepPurple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                );
              },
            ),
          ],

        ),
      ),
    );
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
