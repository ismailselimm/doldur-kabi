import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    String userEmail = currentUser!.email!;
    String userName = currentUser!.displayName ?? "Bilinmeyen Kullanıcı";
    String userImage = currentUser!.photoURL ??
        "https://cdn-icons-png.flaticon.com/512/847/847969.png"; // Varsayılan avatar

    await _firestore.collection('posts').doc(widget.postId).collection('comments').add({
      'text': _commentController.text.trim(),
      'createdAt': DateTime.now().toUtc(),
      'userEmail': userEmail,
      'userName': userName,
      'userImage': userImage,
    });

    // Yorum sayısını artır
    await _firestore.collection('posts').doc(widget.postId).update({
      'comments': FieldValue.increment(1),
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye açıldığında ekranın sıkışmasını engelle
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Yorumlar',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Henüz yorum yok.",
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                var comments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var comment = comments[index].data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(comment['userImage'] ??
                                "https://cdn-icons-png.flaticon.com/512/847/847969.png"),
                            radius: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment['userName'] ?? "Bilinmeyen Kullanıcı",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['text'],
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          AnimatedPadding(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 10, // Biraz yukarı çekildi
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Dikey padding azaltıldı
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20), // Hafif köşeler ekledik
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: GoogleFonts.poppins(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: "Yorum ekle...",
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Daha dengeli boşluk
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addComment,
                    child: Container(
                      padding: const EdgeInsets.all(10), // Buton biraz küçüldü
                      decoration: const BoxDecoration(
                        color: Color(0xFF9346A1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 22), // Buton boyutu optimize edildi
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
