import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gizlilik Politikası',
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
            const SizedBox(height: 20),
            Text(
              'Gizlilik Politikası',
              style: GoogleFonts.montserrat(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('1. Verilerin Toplanması'),
                    _buildSectionText(
                      'Uygulama, kullanıcı verilerini toplarken gizlilik ilkelerine uygun hareket eder. '
                          'Veriler yalnızca kullanıcı deneyimini iyileştirmek amacıyla toplanır.',
                    ),
                    _buildSectionTitle('2. Verilerin Saklanması'),
                    _buildSectionText(
                      'Toplanan veriler güvenli sunucularda saklanır ve izinsiz erişimlere karşı korunur. '
                          'Veriler, yalnızca kullanım amacına uygun süre boyunca saklanır.',
                    ),
                    _buildSectionTitle('3. Verilerin Paylaşımı'),
                    _buildSectionText(
                      'Kullanıcı verileri, kullanıcının izni olmadan üçüncü taraflarla paylaşılmaz. '
                          'Yalnızca yasal zorunluluk durumlarında veriler ilgili makamlarla paylaşılabilir.',
                    ),
                    _buildSectionTitle('4. Kullanıcı Hakları'),
                    _buildSectionText(
                      'Kullanıcılar, kişisel verilerine erişme, düzeltme ve silme haklarına sahiptir. '
                          'Bu haklarla ilgili talepler, uygulama içinden destek ekibiyle iletişime geçilerek yapılabilir.',
                    ),
                    _buildSectionTitle('5. Güncellemeler'),
                    _buildSectionText(
                      'Gizlilik politikası, gerekli görüldüğü durumlarda güncellenebilir. '
                          'Güncellemeler, kullanıcıya bildirilir ve kullanıcıların incelemesi beklenir.',
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Divider(
          color: Colors.deepPurpleAccent,
          thickness: 1.2,
        ),
      ],
    );
  }

  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}
