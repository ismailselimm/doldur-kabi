import 'package:doldur_kabi/screens/home_screens/notification_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<bool> _isRead = [];
  List<String> _notifications = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white, size: 33),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
        child: Text(
          "Henüz bildiriminiz bulunmamaktadır",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: _isRead[index] ? Colors.grey[300] : Colors.white,
            child: ListTile(
              leading: Icon(
                _isRead[index] ? Icons.mark_email_read : Icons.notifications,
                color: Color(0xFF9346A1),
              ),
              title: Text(
                _notifications[index],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isRead[index] ? Colors.black54 : Colors.black,
                ),
              ),
              subtitle: Text(
                'Bu bir örnek bildirim mesajıdır.',
                style: GoogleFonts.poppins(fontSize: 14, color: _isRead[index] ? Colors.black54 : Colors.grey[700]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.mark_email_read, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        _isRead[index] = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _notifications.removeAt(index);
                        _isRead.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
