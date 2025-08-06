import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
              'Kediler her zaman yalnız yaşamayı tercih ederler ❌',
              'Gerçekte, kediler sevgi dolu olabilir ve sahiplerine yakın olmak isteyebilirler. Yalnız kalmayı sevmemeleri durumu her kedinin kişiliğine göre değişir ✅',
              Colors.orange,
              FontAwesomeIcons.cat,
            ),
            _buildMythSection(
              'Köpekler sadece et yer ❌',
              'Köpekler aslında çok çeşitli besinleri severler. Sebzeler, meyveler ve tahıllar da onlar için uygundur, ancak dengeli bir diyetle beslenmeleri önemlidir ✅',
              Colors.green,
              FontAwesomeIcons.bone,
            ),
            _buildMythSection(
              'Kediler suyu sevmez ❌',
              'Birçok kedi aslında suyu sever ve içmeyi ihmal etmez. Ancak suyun hareketli olduğu durumlarda daha fazla ilgi gösterebilirler ✅',
              Colors.blue,
              FontAwesomeIcons.water,
            ),
            _buildMythSection(
              'Köpekler sadece tek bir tür mamayla beslenmeli ❌',
              'Köpeklerin sağlıklı gelişebilmesi için dengeli bir diyet gereklidir. Yaşlarına, cinslerine ve sağlık durumlarına göre farklı türde mamalar önerilir ✅',
              Colors.red,
              FontAwesomeIcons.dog,
            ),
            _buildMythSection(
              'Kediler gece görüşü süperdir, karanlıkta her şeyi görebilir ❌',
              'Kedilerin gece görüşü insanlara göre daha iyidir, ancak tamamen karanlıkta göremezler. Hafif bir ışık kaynağına ihtiyaç duyarlar ✅',
              Colors.purple,
              FontAwesomeIcons.eye,
            ),
            _buildMythSection(
              'Köpeklerin ağızları insanlardan daha temizdir ❌',
              'Köpeklerin ağızlarında da bakteri bulunur. İnsanlardan farklı bakteri türlerine sahiptirler, ancak bu onların daha temiz olduğu anlamına gelmez ✅',
              Colors.brown,
              FontAwesomeIcons.tooth,
            ),
            _buildMythSection(
              'Kediler hep ayaklarının üstüne düşer ❌',
              'Kediler esnek vücut yapıları sayesinde çoğu zaman ayakları üzerine düşebilirler, ancak yüksekten düşerlerse ciddi şekilde yaralanabilirler ✅',
              Colors.cyan,
              FontAwesomeIcons.arrowDown,
            ),
            _buildMythSection(
              'Köpekler insan duygularını anlamaz ❌',
              'Araştırmalar, köpeklerin insan duygularını yüz ifadeleri ve tonlamalar aracılığıyla anlayabildiğini göstermektedir. Sahiplerinin ruh haline göre tepki verebilirler ✅',
              Colors.amber,
              FontAwesomeIcons.faceSmile,
            ),
            _buildMythSection(
              ' Kediler insanlara bağlı \n değildir  ❌',
              'Kediler sahiplerine oldukça bağlı olabilir. Bazıları çok bağımsız görünse de, sahiplerinin yanında olmayı severler ✅',
              Colors.pink,
              FontAwesomeIcons.heart,
            ),
            _buildMythSection(
              'Köpekler sadece oyun oynamak ister ❌',
              'Köpekler oyun oynamayı sever, ancak aynı zamanda zihinsel uyarı ve eğitime de ihtiyaç duyarlar ✅',
              Colors.deepOrange,
              FontAwesomeIcons.paw,
            ),
            _buildMythSection(
              'Kediler çiğ etle beslenmelidir ❌',
              'Çiğ et bazı kediler için riskli olabilir. Dengeli bir beslenme için ticari veya veteriner onaylı diyet önerilir ✅',
              Colors.teal,
              FontAwesomeIcons.drumstickBite,
            ),
            _buildMythSection(
              'Köpekler suçlu hissedebilir ❌',
              'Köpekler, sahiplerinin ses tonu ve yüz ifadelerine tepki verir, ancak insanlar gibi suçluluk hissetmezler ✅',
              Colors.lime,
              FontAwesomeIcons.solidFaceSadTear,
            ),
            _buildMythSection(
              'Kediler süt içmelidir ❌',
              'Birçok kedi laktoza karşı duyarlıdır ve süt içmek sindirim sorunlarına neden olabilir ✅',
              Colors.indigo,
              FontAwesomeIcons.mugHot,
            ),
            _buildMythSection(
              'Köpekler insan yemeklerini yiyebilir ❌',
              'Bazı insan yiyecekleri köpekler için zararlı olabilir. Özellikle çikolata, soğan ve üzüm toksiktir ✅',
              Colors.deepPurple,
              FontAwesomeIcons.utensils,
            ),
            _buildMythSection(
              'Kediler eğitilemez ❌',
              'Kediler tıpkı köpekler gibi eğitilebilir, ancak farklı motivasyonlarla çalışırlar. Ödüller ve sabırla eğitilebilirler ✅',
              Colors.lightBlue,
              FontAwesomeIcons.graduationCap,
            ),
            _buildMythSection(
              'Köpekler renkleri göremez ❌',
              'Köpekler insanlara göre daha az renk görse de, mavi ve sarı tonlarını ayırt edebilirler ✅',
              Colors.orange,
              FontAwesomeIcons.eyeDropper,
            ),
            _buildMythSection(
              ' Kediler sahiplerini \n umursamaz ❌',
              'Kediler sahiplerini takip eder, onları koklayarak tanır ve bazen onlara sevgi gösterir ✅',
              Colors.grey,
              FontAwesomeIcons.user,
            ),
            _buildMythSection(
              'Köpekler yaşlandıkça öğrenmeyi bırakır ❌',
              'Köpekler yaşlandıkça da yeni şeyler öğrenebilirler, ancak eğitim süreci biraz daha uzun sürebilir ✅',
              Colors.blueGrey,
              FontAwesomeIcons.brain,
            ),
            _buildMythSection(
              'Kediler hep tembeldir ❌',
              'Kediler gün içinde uzun süre uyusa da, aslında oldukça aktif olabilirler ve oyun oynamaktan hoşlanırlar ✅',
              Colors.lightGreen,
              FontAwesomeIcons.running,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMythSection(
      String myth, String explanation, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 26, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  myth,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }


}
