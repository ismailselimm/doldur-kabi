import 'package:doldur_kabi/screens/community_screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/report_dialog.dart';

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

    // Firestore'dan güncel kullanıcı bilgilerini al
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final userData = userDoc.data();

    if (userData == null) return;

    String userEmail = userData['email'] ?? currentUser!.email!;
    String userName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
    String userImage = userData['profileUrl'] ?? "https://cdn-icons-png.flaticon.com/512/847/847969.png";

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': _commentController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'userEmail': userEmail,
      'userName': userName,
      'userImage': userImage,
      'userId': currentUser!.uid, // 👈 Bunu ekle

    });

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
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
                    final Timestamp? timestamp = comment['createdAt'];
                    final String formattedDate = timestamp != null
                        ? "${timestamp.toDate().day.toString().padLeft(2, '0')}.${timestamp.toDate().month.toString().padLeft(2, '0')}.${timestamp.toDate().year} ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                        : "";

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
                          // 👤 Profil resmi
                          GestureDetector(
                            onTap: () => _openUserProfile(comment['userEmail']),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                comment['userImage'] ?? "https://cdn-icons-png.flaticon.com/512/847/847969.png",
                              ),
                              radius: 30,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // İçerik + üç nokta
                          Expanded(
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 30), // sağa boşluk bırak üç nokta için
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _openUserProfile(comment['userEmail']),
                                        child: Text(
                                          comment['userName'] ?? "Bilinmeyen Kullanıcı",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        comment['text'],
                                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                                      ),
                                      if (formattedDate.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            formattedDate,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // sağ üst sabit üç nokta
                                Positioned(
                                  top: 5,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _showCommentActionsBottomSheet(
                                      context,
                                      comment,
                                      comments[index].id,
                                    ),
                                    child: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
                                  ),

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

  void showTopSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showCommentActionsBottomSheet(BuildContext context, Map<String, dynamic> comment, String commentId) {
    final isMyComment = comment['userId'] == currentUser?.uid;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            if (isMyComment)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.black87),
                title: const Text("Yorumu sil"),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .delete();

                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .update({
                    'comments': FieldValue.increment(-1),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Yorum silindi")),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.black87),
              title: const Text("Bu yorumu bildir"),
              onTap: () {
                Navigator.pop(context);
                showReportDialog(
                  context,
                  targetType: 'Yorum',
                  targetId: commentId,
                  targetUserEmail: comment['userEmail'] ?? '',
                  targetTitle: comment['text'] ?? '',
                  relatedPostId: widget.postId,
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }


  Future<void> _openUserProfile(String? userEmail) async {
    if (userEmail == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı bulunamadı.")),
      );
      return;
    }

    final userId = snapshot.docs.first.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          userEmail: userEmail,
        ),
      ),
    );
  }


}
