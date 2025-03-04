import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'leader_screen.dart';
import 'adopt_pet_screen.dart';
import 'lost_pets_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF9346A1),
          leading: IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.white),
            tooltip: 'Puan Tablosu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaderboardScreen()),
              );
            },
          ),
          title: Text(
            'Topluluk',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.pets, color: Colors.white),
              tooltip: 'Sahiplen',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdoptionScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.report_problem, color: Colors.white), // Kayıp Hayvanlar Butonu
              tooltip: 'Kayıp Hayvanlar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LostPetsScreen()), // Yeni Sayfa
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildPostCard(
              context,
              username: 'Ezgi Sena',
              userImage: 'assets/images/avatar2.png',
              postImage: 'assets/images/sample_post.png',
              postDescription: 'Sokak hayvanları için mama ve su bıraktım 💖 #DoldurKabı',
              likes: 120,
              comments: 15,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF9346A1),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()), // ✅ Yeni sayfaya yönlendir
          );
        },
      ),
    );
  }

  Widget _buildPostCard(
      BuildContext context, {
        required String username,
        required String userImage,
        required String postImage,
        required String postDescription,
        required int likes,
        required int comments,
      }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(userImage),
              radius: 24,
            ),
            title: Text(
              username,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              '1 saat önce',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.more_vert),
          ),
          Image.asset(
            postImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              postDescription,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border_outlined, color: Colors.black),
                      onPressed: () {
                        // Beğenme işlevi
                      },
                    ),
                    Text(
                      '$likes',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined, color: Colors.black),
                      onPressed: () {
                        // Yorum işlevi
                      },
                    ),
                    Text(
                      '$comments',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded, color: Colors.black),
                  onPressed: () {
                    // Paylaşma işlevi
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}