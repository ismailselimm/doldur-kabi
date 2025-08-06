import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../community_screens/user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverEmail;

  ChatScreen({required this.receiverEmail});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? receiverId;
  bool iAmBlocked = false; // 🔥 karşı taraf seni engellemiş mi
  late String currentUserEmail;
  late String chatId;
  String receiverName = "Yükleniyor...";
  String receiverProfileImage = "";
  bool isBlocked = false;     // Ben onu engelledim mi


  void _checkIfBlocked() async {
    try {
      final query = await _firestore.collection('blocked_users')
          .where('blockingUser', isEqualTo: currentUserEmail)
          .where('blockedUser', isEqualTo: widget.receiverEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          isBlocked = true;
        });
      } else {
        setState(() {
          isBlocked = false;
        });
      }
    } catch (e) {
      print("Engel kontrolü hatası: $e");
    }
  }


  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;
    if (user == null) {
      print("❌ Hata: Kullanıcı giriş yapmamış!");
      Navigator.pop(context);
      return;
    }

    if (widget.receiverEmail == user.email) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                SizedBox(width: 8),
                Expanded(child: Text("Kendinize mesaj gönderemezsiniz 🙂")),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      });
      return;
    }

    currentUserEmail = user.email!;
    List<String> userEmails = [currentUserEmail, widget.receiverEmail];
    userEmails.sort();
    chatId = userEmails.join("_");

    _markMessagesAsRead();
    _getReceiverInfo();

    _checkIfBlocked();     // Ben engelledim mi
    _checkIfIAmBlocked();  // O beni engelledi mi ← ⬅⬅⬅ BU ARTIK currentUserEmail TANIMLANDIKTAN SONRA
  }


  void _markMessagesAsRead() async {
    var receivedMessages = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .where('receiverEmail', isEqualTo: currentUserEmail)
        .where('isRead', isEqualTo: false)
        .get();

    if (receivedMessages.docs.isNotEmpty) {
      for (var msg in receivedMessages.docs) {
        await msg.reference.update({'isRead': true});
      }

      // **🔥 Chat açıldığında son mesajın "okundu" olduğunu Firebase'e ekle**
      await _firestore.collection('messages').doc(chatId).update({'lastMessageRead': true});
    }
  }



  Future<void> _getReceiverInfo() async {
    var userSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: widget.receiverEmail)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      var userDoc = userSnapshot.docs.first;
      var userData = userDoc.data();
      String fullName = "${userData['firstName']} ${userData['lastName']}";

      List<String> nameParts = fullName.split(" ");
      if (nameParts.length > 1) {
        String shortLastName = "${nameParts.last[0]}.";
        fullName = "${nameParts.sublist(0, nameParts.length - 1).join(" ")} $shortLastName";
      }

      setState(() {
        receiverName = fullName;
        receiverProfileImage = userData['profileUrl'] ?? "";
        receiverId = userDoc.id; // 🔥 kullanıcı ID'si
      });
    } else {
      setState(() {
        receiverName = "Bilinmeyen Kullanıcı";
        receiverProfileImage = "";
        receiverId = ""; // boş bırak
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: _goToUserProfile,
              child: CircleAvatar(
                backgroundImage: receiverProfileImage.isNotEmpty
                    ? NetworkImage(receiverProfileImage)
                    : const AssetImage("assets/images/avatar1.png") as ImageProvider,
                radius: 20,
              ),
            ),
            const SizedBox(width: 15), // 🟣 Profil resmi ile isim arası boşluk
            GestureDetector(
              onTap: _goToUserProfile,
              child: Text(
                receiverName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "block_user") _blockUser();
              if (value == "unblock_user") _unblockUser();
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            itemBuilder: (context) => [
              if (!isBlocked)
                PopupMenuItem(
                  value: "block_user",
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Kişiyi Engelle",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isBlocked)
                PopupMenuItem(
                  value: "unblock_user",
                  child: Row(
                    children: [
                      Icon(Icons.lock_open, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Engeli Kaldır",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )

        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // 🔹 Arkaplan görseli
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/mesajlar.png',
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // bulanıklık seviyesi
                    child: Container(
                      color: Colors.white.withOpacity(0), // Şeffaf overlay, gerekiyor
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 İçerik
            Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: _firestore
                        .collection('messages')
                        .doc(chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      var messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message = messages[index].data() as Map<String, dynamic>;
                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  ),
                ),

                // 🔹 Mesaj yazma kutusu
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                    left: 12,
                    right: 12,
                    top: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF9FF).withOpacity(0.95), // biraz transparanlık ekledim
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: (isBlocked || iAmBlocked)
                      ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      isBlocked
                          ? "Bu kişiyi engellediniz. Daha fazla mesaj gönderip alamazsınız."
                          : "Bu kullanıcı sizi engellemiş. Ona daha fazla mesaj gönderemezsiniz.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                  )
                      : Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: "Mesajınızı yazın...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          sendMessage(_messageController.text);
                          _messageController.clear();
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),

                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToUserProfile() {
    if (receiverId == null || receiverId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil bilgileri yükleniyor...")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: receiverId!,
          userEmail: widget.receiverEmail,
        ),
      ),
    );
  }



  /// ✅ Kullanıcıyı Engelleme
  void _blockUser() async {
    try {
      await _firestore.collection('blocked_users').add({
        'blockingUser': currentUserEmail,
        'blockedUser': widget.receiverEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        isBlocked = true;
      });

    } catch (e) {
      print("Engelleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bir hata oluştu. ")));
    }
  }

  /// ✅ Kullanıcının Engelini Kaldırma
  void _unblockUser() async {
    try {
      final query = await _firestore.collection('blocked_users')
          .where('blockingUser', isEqualTo: currentUserEmail)
          .where('blockedUser', isEqualTo: widget.receiverEmail)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      setState(() {
        isBlocked = false;
      });

    } catch (e) {
      print("Engel kaldırma hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bir hata oluştu.")));
    }
  }

  /// **🔥 Mesaj Gönderme Fonksiyonu**
  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty || isBlocked) return;

    var messageRef = _firestore.collection('messages').doc(chatId).collection('messages').doc();

    await messageRef.set({
      'senderEmail': currentUserEmail,
      'receiverEmail': widget.receiverEmail,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // 🔥 Başlangıçta mesaj okunmadı
    });

    await _firestore.collection('messages').doc(chatId).set({
      'users': [currentUserEmail, widget.receiverEmail],
      'lastMessage': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    }, SetOptions(merge: true));
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isMe = message['senderEmail'] == currentUserEmail;
    bool isRead = message['isRead'] ?? false; // 🔥 Okunup okunmadığını kontrol et

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.70, // 📌 Maksimum genişlik %75 olacak
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF9346A1) : const Color(0xFFF8E8FF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['text'],
              style: GoogleFonts.poppins(fontSize: 14, color: isMe ? Colors.white : Colors.black87),
              softWrap: true,  // 📌 Metin taşarsa alta geçsin
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _checkIfIAmBlocked() async {
    try {
      final query = await _firestore.collection('blocked_users')
          .where('blockingUser', isEqualTo: widget.receiverEmail) // o seni engellemiş mi
          .where('blockedUser', isEqualTo: currentUserEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          iAmBlocked = true;
        });
      } else {
        setState(() {
          iAmBlocked = false;
        });
      }
    } catch (e) {
      print("Beni engellemiş mi kontrol hatası: $e");
    }
  }



  /// **🔥 Zaman Formatlama Fonksiyonu**
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmeyen Zaman";
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
