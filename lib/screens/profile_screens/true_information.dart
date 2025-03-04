import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MythsPage extends StatelessWidget {
  const MythsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doğru Bilinen Yanlışlar',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildMythSection(
              'Kediler her zaman yalnız yaşamayı tercih ederler 🐱❌',
              'Gerçekte, kediler sevgi dolu olabilir ve sahiplerine yakın olmak isteyebilirler. Yalnız kalmayı sevmemeleri durumu her kedinin kişiliğine göre değişir ✅',
              Colors.orange,
              Icons.pets,
            ),
            _buildMythSection(
              'Köpekler sadece et yer 🐶❌',
              'Köpekler aslında çok çeşitli besinleri severler. Sebzeler, meyveler ve tahıllar da onlar için uygundur, ancak dengeli bir diyetle beslenmeleri önemlidir ✅',
              Colors.green,
              Icons.restaurant,
            ),
            _buildMythSection(
              'Kediler suyu sevmez 💦🐱❌',
              'Birçok kedi aslında suyu sever ve içmeyi ihmal etmez. Ancak suyun hareketli olduğu durumlarda daha fazla ilgi gösterebilirler ✅',
              Colors.blue,
              Icons.water_drop,
            ),
            _buildMythSection(
              'Köpekler sadece tek bir tür mamayla beslenmeli 🦴❌',
              'Köpeklerin sağlıklı gelişebilmesi için dengeli bir diyet gereklidir. Yaşlarına, cinslerine ve sağlık durumlarına göre farklı türde mamalar önerilir ✅',
              Colors.red,
              Icons.food_bank,
            ),
            _buildMythSection(
              'Kediler gece görüşü süperdir, karanlıkta her şeyi görebilir ❌',
              'Kedilerin gece görüşü insanlara göre daha iyidir, ancak tamamen karanlıkta göremezler. Hafif bir ışık kaynağına ihtiyaç duyarlar ✅',
              Colors.purple,
              Icons.visibility,
            ),
            _buildMythSection(
              'Köpeklerin ağızları insanlardan daha temizdir 🦷❌',
              'Köpeklerin ağızlarında da bakteri bulunur. İnsanlardan farklı bakteri türlerine sahiptirler, ancak bu onların daha temiz olduğu anlamına gelmez ✅',
              Colors.brown,
              Icons.health_and_safety,
            ),
            _buildMythSection(
              'Kediler hep ayaklarının üstüne düşer 🐈‍⬛❌',
              'Kediler esnek vücut yapıları sayesinde çoğu zaman ayakları üzerine düşebilirler, ancak yüksekten düşerlerse ciddi şekilde yaralanabilirler ✅',
              Colors.cyan,
              Icons.downhill_skiing,
            ),
            _buildMythSection(
              'Köpekler insan duygularını anlamaz 😢❌',
              'Araştırmalar, köpeklerin insan duygularını yüz ifadeleri ve tonlamalar aracılığıyla anlayabildiğini göstermektedir. Sahiplerinin ruh haline göre tepki verebilirler ✅',
              Colors.amber,
              Icons.mood,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMythSection(
      String myth, String explanation, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      myth,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                explanation,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
