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
                      '1. DoldurKabı Nedir?',
                      'DoldurKabı, sokak hayvanlarının beslenmesi, barınması ve sahiplendirilmesi için toplulukla birlikte çalışan sosyal bir mobil platformdur. '
                          'Mama kapları, hayvan evleri, ilanlar ve topluluk etkileşimi gibi birçok özelliği içerir.',
                    ),
                    _buildExpandableSection(
                      '2. Harita Nasıl Kullanılır?',
                      'Ana sayfadaki harita üzerinden bulunduğunuz bölgedeki mama kaplarını, hayvan evlerini ve kayıp ilanlarını görebilirsiniz. '
                          'Filtre ikonuna dokunarak sadece istediğiniz türdeki verileri görüntüleyebilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '3. Mama Kabı veya Hayvan Evi Nasıl Eklenir?',
                      'Haritada "+" simgesine tıklayarak bulunduğunuz konuma mama kabı veya hayvan evi ekleyebilirsiniz. '
                          'Konum, görsel ve kısa açıklama ekleyerek topluluğa katkıda bulunabilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '4. Bir Noktayı Doldurduğumda Ne Olur?',
                      'Mama kabını fiziksel olarak doldurduktan sonra uygulama üzerinden “Doldurdum” butonuna basabilirsiniz. '
                          'Bu, diğer kullanıcıların o noktanın güncel olduğunu bilmesini sağlar.',
                    ),
                    _buildExpandableSection(
                      '5. Hayvan Sahiplenme İşlemi Nasıl Yapılır?',
                      '"Sahiplendirme" sayfasında yer alan ilanları inceleyebilir, iletişim bilgisi olan ilan sahipleriyle doğrudan mesajlaşabilirsiniz. '
                          'Her sahiplendirme ilanı önce kontrol edilip yayınlanır.',
                    ),
                    _buildExpandableSection(
                      '6. Kayıp Hayvan İlanı Nasıl Verilir?',
                      'Kayıp hayvanınız için "Kayıp" bölümüne girerek fotoğraf, açıklama ve kaybolduğu konumu belirterek ilan oluşturabilirsiniz. '
                          'Bu ilanlar haritada görüntülenebilir.',
                    ),
                    _buildExpandableSection(
                      '7. Topluluk Paylaşımları Nedir?',
                      'Topluluk bölümünde beslemelerinizden, karşılaştığınız hayvanlardan veya ilham veren hikâyelerden gönderiler paylaşabilirsiniz. '
                          'Fotoğraflı gönderiler en fazla 3 resim içerebilir.',
                    ),
                    _buildExpandableSection(
                      '8. Şikayet / Bildirim Sistemi Nasıl Çalışır?',
                      'Her gönderi, yorum veya kullanıcı için "Bildir" seçeneği yer alır. Şüpheli veya uygunsuz içerikleri bildirerek moderasyon ekibine iletebilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '9. Destekçilerimiz ve Belediyeler',
                      'Uygulamada yer alan “Destekçilerimiz” ve “Belediyelerimiz” bölümlerinden katkı sağlayan kurumları ve iş birliklerini görebilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '10. Profil Bilgilerimi Nasıl Güncellerim?',
                      '"Profil" sayfasına girerek ad, soyad, e-posta, profil fotoğrafı gibi bilgilerinizi değiştirebilir; katkı geçmişinizi görüntüleyebilirsiniz.',
                    ),
                    _buildExpandableSection(
                      '11. Onay Sistemi Nedir?',
                      'Kayıp ilanları, sahiplendirme ilanları ve topluluk gönderileri, admin onayıyla yayına alınır. Bu sayede uygulamada içerik kalitesi korunur.',
                    ),
                    _buildExpandableSection(
                      '12. Daha Fazla Destek İçin Ne Yapabilirim?',
                      '“Bize Ulaşın” sayfasından önerilerinizi, teknik sorunları veya iş birliği tekliflerinizi gönderebilirsiniz. '
                          'Ayrıca Instagram sayfamızdan güncellemeleri takip edebilirsiniz.',
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
