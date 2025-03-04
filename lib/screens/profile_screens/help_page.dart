import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yardım',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF9346A1),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Yardım',
              style: GoogleFonts.montserrat(
                fontSize: 28,
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
                    _buildExpandableSection(
                      '1. Uygulama Nasıl Kullanılır?',
                      'Uygulama, sokak hayvanlarına mama ve su bırakılacak yerleri harita üzerinde gösterir. '
                          'Kullanıcılar harita üzerinden besleme noktalarını, hayvan evlerini görüntüleyebilir ve yeni noktalar ekleyebilir.',
                    ),
                    _buildExpandableSection(
                      '2. Kullanıcı Hesabı Nasıl Oluşturulur?',
                      'Uygulamada kullanıcı hesabı oluşturmak için "Kaydol" ekranına gidin. '
                          'E-posta adresinizi, şifrenizi ve ad-soyad bilgilerinizi girerek kaydınızı tamamlayabilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '3. Besleme Noktası Nasıl Eklenir?',
                      'Bir besleme noktası eklemek için harita üzerinde "Yeni Nokta Ekle" seçeneğine tıklayın. '
                          'Burası, sokak hayvanlarına mama ve su bırakmak için uygun bir alan olarak eklenir.',
                    ),
                    _buildExpandableSection(
                      '4. Harita Neden Güncelleniyor?',
                      'Harita, kullanıcılardan gelen yeni besleme noktalarıyla güncellenir. '
                          'Bu, daha fazla hayvana yardımcı olmak ve doğru bilgi sağlamak için gereklidir.',
                    ),
                    _buildExpandableSection(
                      '5. Destek, Öneri, Şikayet',
                      'Uygulama içindeki "Bize Ulaşın" sayfası üzerinden bizimle iletişime geçebilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '6. Hayvan Sahiplenme Nasıl Yapılır?',
                      'Uygulama içerisindeki "Sahiplenme" bölümünden hayvan sahiplenme ilanlarına ulaşabilirsiniz. '
                          'Bir hayvanı sahiplenmek isterseniz, ilan sahibine mesaj göndererek iletişime geçebilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '7. Kayıp Hayvanlar Nasıl Bildirilir?',
                      'Eğer kayıp bir hayvan gördüyseniz veya kaybolan hayvanınızı arıyorsanız, "Kayıp Hayvanlar" bölümüne ilan ekleyebilirsiniz. '
                          'Bu ilanlar haritada kayboldukları yerle birlikte görüntülenecektir.',
                    ),
                    _buildExpandableSection(
                      '8. Bildirimler Nasıl Çalışır?',
                      'Uygulama, önemli güncellemeleri ve acil durumları size bildirim olarak gönderebilir. '
                          'Ayarlar bölümünden bildirimleri açıp kapatabilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '9. Toplulukta Nasıl Paylaşım Yapabilirim?',
                      'Uygulama içindeki "Topluluk" alanında, besleme noktalarınızın fotoğraflarını ve deneyimlerinizi paylaşabilirsiniz. '
                          'Bu, diğer gönüllülerin de besleme sürecine katkıda bulunmasını teşvik eder.',
                    ),
                    _buildExpandableSection(
                      '10. Bağış Yaparak Nasıl Destek Olabilirim?',
                      'Eğer sokak hayvanlarına destek olmak isterseniz, uygulama içindeki "Destekçilerimiz" sekmesinden bağış yapabilirsiniz. '
                          'Bağışlar, mama alımı ve veteriner destekleri için kullanılacaktır.',
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

  Widget _buildExpandableSection(String title, String content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
