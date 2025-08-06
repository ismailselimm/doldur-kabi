import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> leaderboardData = [
      {'rank': 1, 'name': 'Ezgi', 'points': 250},
      {'rank': 2, 'name': 'Ayşe', 'points': 200},
      {'rank': 3, 'name': 'Zeynep', 'points': 150},
      {'rank': 4, 'name': 'Fatma', 'points': 100},
      {'rank': 5, 'name': 'Sude', 'points': 50},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Puan Tablosu 🏆',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9346A1), Color(0xFF6A1B9A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildTopThree(leaderboardData),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: leaderboardData.length - 3,
                itemBuilder: (context, index) {
                  final user = leaderboardData[index + 3];
                  return _buildLeaderboardTile(user, false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopThree(List<Map<String, dynamic>> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMedalTile(data[1], "🥈", Colors.grey.shade400, 80), // 2. sıradaki
        const SizedBox(width: 15),
        _buildMedalTile(data[0], "🥇", Colors.amber, 100), // 1. sıradaki (en büyük gösterilir)
        const SizedBox(width: 15),
        _buildMedalTile(data[2], "🥉", Colors.brown.shade400, 70), // 3. sıradaki
      ],
    );
  }

  Widget _buildMedalTile(Map<String, dynamic> user, String emoji, Color color, double size) {
    return Column(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: color,
          child: Text(
            emoji,
            style: TextStyle(fontSize: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user['name'],
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          "${user['points']} Puan",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> user, bool isTopThree) {
    return Card(
      color: isTopThree ? Colors.transparent : Colors.white,
      elevation: isTopThree ? 0 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF9346A1),
          child: Text(
            '${user['rank']}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        title: Text(
          user['name'],
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: isTopThree ? Colors.white : Colors.black),
        ),
        trailing: Text(
          '${user['points']} Puan',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: isTopThree ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
