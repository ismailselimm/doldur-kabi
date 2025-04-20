import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  late String currentUserEmail;
  late String chatId;
  String receiverName = "Yükleniyor...";
  String receiverProfileImage = "";
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ Hata: Kullanıcı giriş yapmamış!");
      Navigator.pop(context);
      return;
    }
    currentUserEmail = user.email!;

    List<String> userEmails = [currentUserEmail, widget.receiverEmail];
    userEmails.sort();
    chatId = userEmails.join("_");

    _getReceiverInfo();
    _checkIfBlocked();
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
    var userSnapshot = await _firestore.collection('users').where('email', isEqualTo: widget.receiverEmail).get();
    if (userSnapshot.docs.isNotEmpty) {
      var userData = userSnapshot.docs.first.data();
      String fullName = "${userData['firstName']} ${userData['lastName']}";

      List<String> nameParts = fullName.split(" ");
      if (nameParts.length > 1) {
        String shortLastName = "${nameParts.last[0]}.";
        fullName = "${nameParts.sublist(0, nameParts.length - 1).join(" ")} $shortLastName";
      }

      setState(() {
        receiverName = fullName;
        receiverProfileImage = userData['profileUrl'] ?? "";
      });
    } else {
      setState(() {
        receiverName = "Bilinmeyen Kullanıcı";
        receiverProfileImage = "";
      });
    }
  }

  Future<void> _checkIfBlocked() async {
    var blockedUserSnapshot = await _firestore.collection('blocked_users').doc(currentUserEmail).get();
    if (blockedUserSnapshot.exists) {
      List blockedUsers = blockedUserSnapshot['blocked'] ?? [];
      if (blockedUsers.contains(widget.receiverEmail)) {
        setState(() {
          isBlocked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: receiverProfileImage.isNotEmpty
                  ? NetworkImage(receiverProfileImage)
                  : const AssetImage("assets/images/default_profile.png") as ImageProvider,
              radius: 20,
            ),
            const SizedBox(width: 8),
            Text(
              receiverName,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "clear_chat") _clearChat();
              if (value == "block_user") _blockUser();
              if (value == "unblock_user") _unblockUser();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "clear_chat", child: Text("Sohbeti Temizle")),
              if (!isBlocked) const PopupMenuItem(value: "block_user", child: Text("Kişiyi Engelle")),
              if (isBlocked) const PopupMenuItem(value: "unblock_user", child: Text("Engeli Kaldır")),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false, // ✅ Klavyeye yapışık olacak
        child: Column(
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

            // ✅ WhatsApp gibi klavyeye yapışık mesaj kutusu
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 30, // Daha iyi hizalama
                left: 10, right: 10, top: 10, // Hafif boşluk ekleyelim ki daha iyi görünsün
              ),              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Mesajınızı yazın...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      sendMessage(_messageController.text);
                      _messageController.clear();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF9346A1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔥 Sohbeti Temizleme Fonksiyonu**
  void _clearChat() async {
    var messages = await _firestore.collection('messages').doc(chatId).collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sohbet temizlendi.")));
  }

  /// **🔥 Kullanıcıyı Engelleme Fonksiyonu**
  void _blockUser() async {
    await _firestore.collection('blocked_users').doc(currentUserEmail).set({
      'blocked': FieldValue.arrayUnion([widget.receiverEmail])
    }, SetOptions(merge: true));

    setState(() {
      isBlocked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı engellendi.")));
  }

  /// **🔥 Kullanıcının Engeli Kaldırma Fonksiyonu**
  void _unblockUser() async {
    await _firestore.collection('blocked_users').doc(currentUserEmail).update({
      'blocked': FieldValue.arrayRemove([widget.receiverEmail])
    });

    setState(() {
      isBlocked = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Engel kaldırıldı.")));
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

  /// **🔥 Zaman Formatlama Fonksiyonu**
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmeyen Zaman";
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
