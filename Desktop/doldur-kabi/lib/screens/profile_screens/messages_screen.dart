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
    String? currentUserEmail = _auth.currentUser?.email;

    if (currentUserEmail == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Sohbetler")),
        body: Center(child: Text("Giriş yapmadınız!")),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF0E6F4),
      appBar: AppBar(
        title: Text(
          'Mesajlarım',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('messages')
            .where('users', arrayContains: currentUserEmail)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Henüz sohbetiniz yok.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }

          var chats = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12.0),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index].data() as Map<String, dynamic>;
              String chatId = chats[index].id;
              String lastMessage = chat['lastMessage'] ?? "Henüz mesaj yok";
              bool isRead = chat['lastMessageReadBy']?.contains(currentUserEmail) ?? false;

              String receiverEmail = (chat['users'] as List)
                  .firstWhere((email) => email != currentUserEmail, orElse: () => "Bilinmeyen");

              return FutureBuilder<QuerySnapshot>(
                future: _firestore.collection('users').where('email', isEqualTo: receiverEmail).get(),
                builder: (context, userSnapshot) {
                  String receiverName = "Bilinmeyen Kullanıcı";
                  String profilePic = "https://cdn-icons-png.flaticon.com/512/847/847969.png"; // Varsayılan avatar

                  if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                    var userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    receiverName = "${userData['firstName']} ${userData['lastName']}";

                    if (userData['profileUrl'] != null && userData['profileUrl'].isNotEmpty) {
                      profilePic = userData['profileUrl'];
                    }
                  }

                  return GestureDetector(
                    onTap: () async {
                      await _markMessagesAsRead(chatId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(receiverEmail: receiverEmail),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            spreadRadius: 3,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(profilePic),
                            backgroundColor: Colors.grey[300],
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  receiverName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "delete_chat") _deleteChat(chatId);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: "delete_chat", child: Text("Sohbeti Sil")),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markMessagesAsRead(String chatId) async {
    await _firestore.collection('messages').doc(chatId).update({
      'lastMessageReadBy': FieldValue.arrayUnion([_auth.currentUser?.email]),
    });
  }

  void _deleteChat(String chatId) async {
    var messages = await _firestore.collection('messages').doc(chatId).collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('messages').doc(chatId).delete();

    print("✅ Sohbet tamamen silindi: $chatId");

    if (mounted) {
      setState(() {});
    }
  }
}
