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
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF9346A1),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
                "Henüz bir sohbet başlatılmamış.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          var chats = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index].data() as Map<String, dynamic>;
              String chatId = chats[index].id;
              String lastMessage = chat['lastMessage'] ?? "Henüz mesaj yok";
              bool isRead = chat['lastMessageReadBy']?.contains(currentUserEmail) ?? false;

              String receiverEmail = (chat['users'] as List)
                  .firstWhere((email) => email != currentUserEmail, orElse: () => "Bilinmeyen");

              String lastMessageSender = chat['lastMessageSender'] ?? '';
              bool isLastFromMe = lastMessageSender == currentUserEmail;
              Timestamp? timestamp = chat['timestamp'];


              return FutureBuilder<QuerySnapshot>(
                future: _firestore.collection('users').where('email', isEqualTo: receiverEmail).get(),
                builder: (context, userSnapshot) {
                  String receiverName = "Bilinmeyen Kullanıcı";
                  String profilePic = "https://cdn-icons-png.flaticon.com/512/847/847969.png";

                  if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                    var userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    receiverName = "${userData['firstName']} ${userData['lastName']}";
                    if (userData['profileUrl'] != null && userData['profileUrl'].isNotEmpty) {
                      profilePic = userData['profileUrl'];
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GestureDetector(
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 👤 PROFİL
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(profilePic),
                                  backgroundColor: Colors.grey[300],
                                ),
                                if (lastMessage != "Henüz mesaj yok")
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // 📦 METİN BLOĞU
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🟪 1. SATIR: İsim + Saat
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          receiverName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (timestamp != null)
                                        Text(
                                          _getRelativeTime(timestamp),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // 🟦 2. SATIR: mesaj + boşluk + üç nokta
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 💬 Mesaj
                                      Expanded(
                                        child: Text(
                                          isLastFromMe ? "Sen: $lastMessage" : lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: lastMessage == "Henüz mesaj yok"
                                                ? Colors.grey
                                                : isRead
                                                ? Colors.black87
                                                : Colors.deepPurple,
                                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                            fontStyle: lastMessage == "Henüz mesaj yok"
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // ⋮ Menü butonu (tasarımı ellemiyoruz)
                                      GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                            ),
                                            builder: (context) {
                                              return SafeArea(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      width: 40,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[300],
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    ListTile(
                                                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                      title: const Text("Sohbeti Sil"),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        _showDeleteConfirmation(chatId);
                                                      },
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: const Icon(Icons.more_vert, size: 22),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),



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

  Future<void> _deleteChat(String chatId) async {
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


  String _getRelativeTime(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inSeconds < 60) return '${difference.inSeconds} sn önce';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} sa önce';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';

    return '${messageTime.day}.${messageTime.month}.${messageTime.year}';
  }


  void _showDeleteConfirmation(String chatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
                SizedBox(height: 16),
                Text(
                  "Sohbeti Sil",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Bu sohbeti silmek istediğinizden emin misiniz?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child: Text("Vazgeç",
                          style: GoogleFonts.poppins(color: Colors.grey[700])),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _deleteChat(chatId);
                        Navigator.of(context).pop();
                      },
                      label: Text("Sil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}
