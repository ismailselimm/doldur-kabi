import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  ChatScreen({required this.receiverId, required this.receiverName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  String? chatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // ✅ Firestore'da mesaj yapısını otomatik olarak oluşturur
  Future<void> _initializeChat() async {
    String senderId = _auth.currentUser!.uid;
    String receiverId = widget.receiverId;

    List<String> ids = [senderId, receiverId];
    ids.sort();
    chatId = ids.join("_");

    DocumentReference chatRef = _firestore.collection('messages').doc(chatId);

    try {
      DocumentSnapshot chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        print("DEBUG: Yeni sohbet dokümanı oluşturuluyor -> $chatId");

        await chatRef.set({
          'users': [senderId, receiverId],
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("✅ DEBUG: Sohbet başarıyla oluşturuldu!");
      }
    } catch (e) {
      print("❌ ERROR: Sohbet oluşturma hatası -> $e");
    }
  }

  // ✅ Mesaj gönderme
  void _sendMessage() async {
    if (_messageController.text.isEmpty || chatId == null) return;

    String senderId = _auth.currentUser!.uid;
    String receiverId = widget.receiverId;
    String messageText = _messageController.text.trim();

    try {
      CollectionReference messagesRef =
      _firestore.collection('messages').doc(chatId).collection('messages');

      await messagesRef.add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print("✅ DEBUG: Mesaj Firestore'a kaydedildi!");

      _messageController.clear();
    } catch (e) {
      print("❌ ERROR: Mesaj gönderme hatası -> $e");
    }
  }

  // ✅ Mesajları Firestore'dan çeker
  Stream<QuerySnapshot> _getMessages() {
    if (chatId == null) {
      print("⚠️ WARNING: chatId bulunamadı, mesajlar çekilemiyor.");
      return Stream.empty();
    }

    return _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF9346A1),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessages(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Henüz mesaj yok.", style: GoogleFonts.poppins()));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index].data() as Map<String, dynamic>;
                    bool isMe = message['senderId'] == _auth.currentUser!.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.purple[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message['message'],
                          style: GoogleFonts.poppins(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Mesajınızı yazın...",
                          border: InputBorder.none,
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF9346A1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
