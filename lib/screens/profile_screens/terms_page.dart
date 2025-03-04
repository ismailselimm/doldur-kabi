import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kullanım Şartları',
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
              'Kullanım Şartları',
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
                    _buildSectionTitle('1. Genel Hükümler'),
                    _buildSectionText(
                      'Uygulama, kullanıcıların sokak hayvanlarını beslemeleri için bir platform sunar. '
                          'Uygulama üzerinden yapılan tüm etkileşimler, belirtilen kullanım şartları çerçevesinde gerçekleşir.',
                    ),
                    _buildSectionTitle('2. Kullanıcı Sorumlulukları'),
                    _buildSectionText(
                      'Kullanıcılar, uygulamayı yalnızca yasalara uygun ve etik kurallara saygılı bir şekilde kullanmakla yükümlüdür. '
                          'Kullanıcılar, hayvanlara zarar vermekten kaçınmalı ve çevreye duyarlı olmalıdır.',
                    ),
                    _buildSectionTitle('3. Yasaklı İçerikler'),
                    _buildSectionText(
                      'Uygulama üzerinden zararlı, nefret dolu, tehditkar, yanıltıcı ya da yasa dışı içerikler paylaşmak yasaktır. '
                          'Böyle bir içerik paylaşıldığı takdirde kullanıcı hesabı askıya alınabilir veya kalıcı olarak silinebilir.',
                    ),
                    _buildSectionTitle('4. Veri Toplama ve Gizlilik'),
                    _buildSectionText(
                      'Uygulama, kullanıcı verilerini yalnızca kullanım deneyimini iyileştirmek amacıyla toplar ve saklar. '
                          'Toplanan veriler, gizlilik politikasına uygun olarak korunur.',
                    ),
                    _buildSectionTitle('5. Hizmetin Kesintisi ve Değişiklikler'),
                    _buildSectionText(
                      'Uygulama hizmetlerinde değişiklik yapılabilir veya hizmet kesintileri yaşanabilir. '
                          'Kullanıcılar, uygulamanın tamamen veya geçici olarak erişilemez olabileceğini kabul eder.',
                    ),
                    _buildSectionTitle('6. Kullanıcı Hesabı ve Güvenlik'),
                    _buildSectionText(
                      'Kullanıcılar, hesaplarının güvenliğini sağlamakla yükümlüdür. '
                          'Hesap bilgilerinizi paylaşmamalı ve başkalarının hesabınıza erişmesine izin vermemelisiniz.',
                    ),
                    _buildSectionTitle('7. Sorumluluk Reddi'),
                    _buildSectionText(
                      'Uygulama, kullanıcıların sokak hayvanlarını beslemeleriyle ilgili herhangi bir sorumluluk kabul etmez. '
                          'Kullanıcılar, uygulama üzerinden gerçekleştirdiği her türlü faaliyetten sorumludur.',
                    ),
                    _buildSectionTitle('8. İletişim'),
                    _buildSectionText(
                      'Herhangi bir sorunuz veya kullanım şartlarıyla ilgili bir endişeniz varsa, bizimle iletişime geçebilirsiniz. '
                          'İletişim bilgileri için uygulamanın destek sayfasına bakabilirsiniz.',
                    ),
                    const SizedBox(height: 20),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
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
            thickness: 1.2,
          ),
        ],
      ),
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
