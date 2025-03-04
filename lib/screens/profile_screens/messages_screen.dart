import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Gelen Mesajlar',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('messages')
            .where('receiverId', isEqualTo: _auth.currentUser?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print("DEBUG ERROR: Firestore Hatası: ${snapshot.error}");
            return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            print("DEBUG: Veri çekilmiyor, yükleniyor...");
            return Center(child: CircularProgressIndicator());
          }

          var messages = snapshot.data!.docs;

          if (messages.isEmpty) {
            print("DEBUG: Mesaj bulunamadı.");
            print("DEBUG: Giriş yapan kullanıcının UID'si: ${_auth.currentUser?.uid}");
            return Center(
              child: Text(
                "Henüz mesajınız yok.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }

          print("DEBUG: ${messages.length} mesaj bulundu.");
          return ListView.builder(
            padding: EdgeInsets.all(12.0),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              var message = messages[index].data() as Map<String, dynamic>;

              String senderId = message['senderId'] ?? "Bilinmeyen Kullanıcı";
              String messageText = message['message'] ?? "Mesaj içeriği yok";
              bool isRead = message['isRead'] ?? false;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: message['senderId'],
                        receiverName: message['senderId'], // Gerçek isim çekmek için kullanıcı verisi eklenebilir
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple[300],
                        child: Text(
                          senderId.substring(0, 1),
                          style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderId,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              messageText,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteMessage(messages[index].id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Mesajı "okundu" olarak işaretle
  void _markMessageAsRead(String messageId) {
    _firestore.collection('messages').doc(messageId).update({'isRead': true});
  }

  // Mesajı Firestore'dan sil
  void _deleteMessage(String messageId) {
    _firestore.collection('messages').doc(messageId).delete();
  }
}
