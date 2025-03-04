import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyNoticePage extends StatelessWidget {
  const PrivacyNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aydınlatma Metni',
          style: GoogleFonts.montserrat(fontWeight:
          FontWeight.bold,
            color : Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF9346A1),
        iconTheme: const IconThemeData(
          color: Colors.white, // Geri butonu ve diğer ikonlar beyaz olur
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aydınlatma Metni',
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('1. Toplanan Veriler'),
                    const SizedBox(height: 5),
                    _buildSectionText(
                      'Kişisel Bilgiler: Ad, soyad, e-posta adresi gibi bilgiler, uygulama kaydınız ve profiliniz için toplanır.\n'
                          'Kullanım Verileri: Uygulama kullanım alışkanlıklarınız (tıklama sayıları, etkileşimler vb.) ve cihaz bilgileri (IP adresi, cihaz türü) toplanabilir.\n'
                          'Konum Verisi: Sokak hayvanlarını beslemek amacıyla harita verileriniz kullanılabilir.',
                    ),
                    const SizedBox(height: 15),
                    _buildSectionTitle('2. Verilerin Kullanımı'),
                    const SizedBox(height: 5),
                    _buildSectionText(
                      'Verileriniz, uygulamanın işlevselliğini iyileştirmek, kullanıcı deneyimini özelleştirmek ve uygulama içi hizmetleri sağlamak amacıyla kullanılacaktır.',
                    ),
                    const SizedBox(height: 15),
                    _buildSectionTitle('3. Veri Güvenliği'),
                    const SizedBox(height: 5),
                    _buildSectionText(
                      'Kişisel verileriniz güvenli sunucularda saklanacak ve yalnızca yetkili kişiler tarafından erişilebilecektir.\n'
                          'Uygulama, verilerinizi korumak için endüstri standartlarına uygun güvenlik önlemleri alır.',
                    ),
                    const SizedBox(height: 15),
                    _buildSectionTitle('4. Kullanıcı Hakları'),
                    const SizedBox(height: 5),
                    _buildSectionText(
                      'Kişisel verileriniz üzerinde kontrol sizde olacaktır. Her zaman verilerinize erişebilir, düzeltebilir veya silebilirsiniz.\n'
                          'Bu haklarla ilgili talepleriniz için uygulama içinden bizimle iletişime geçebilirsiniz.',
                    ),
                    const SizedBox(height: 15),
                    _buildSectionTitle('5. Veri Paylaşımı'),
                    const SizedBox(height: 5),
                    _buildSectionText(
                      'Kişisel verileriniz, yalnızca yasal zorunluluklar çerçevesinde ve sizin onayınızla üçüncü taraflarla paylaşılabilir.',
                    ),
                    const SizedBox(height: 15),
                    _buildSectionTitle('6. Güncellemeler ve İletişim'),
                    const SizedBox(height: 5),
                    _buildSectionText(
                      'Bu aydınlatma metni zaman zaman güncellenebilir. Güncellemeler, uygulama üzerinden veya e-posta yoluyla bildirilecektir.\n'
                          'Verilerinizle ilgili herhangi bir soru veya endişeniz olduğunda, lütfen bizimle iletişime geçin.',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Divider(
          color: Colors.deepPurple,
          thickness: 1.5,
        ),
      ],
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.5),
    );
  }
}
