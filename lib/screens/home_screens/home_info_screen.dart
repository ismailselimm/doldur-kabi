import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeInfoScreen extends StatelessWidget {
  const HomeInfoScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF6EFFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Harita Kullanım Kılavuzu',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const SizedBox(height: 20),

                  _buildInfoCard(
                    iconPath: "assets/images/catfood.png",
                    title: "Mama Kapları",
                    description: """
Haritada doluysa 🟢, 3 saatten uzun süredir doldurulmadıysa 🔴 olarak görünür.

Mama kabına tıklayarak:
• Son fotoğrafı görebilir,
• 'Doldur' butonuyla güncel durum fotoğrafı ekleyebilirsiniz.

📸 Her dolum sonrası tarih kaydedilir ve kabın doluluk yüzdesi otomatik hesaplanır.

📌 Mama kaplarının içine doğrudan bakabilen bir sensör sistemimiz bulunmadığı için, 3 saatten uzun süre güncellenmeyen kaplar otomatik olarak “boş” kabul edilir. Bu yöntem, sokaktaki dostlarımızın mama ihtiyacını daha hızlı tespit edebilmemize yardımcı olur.""",
                  ),

                  _buildInfoCard(
                    iconPath: "assets/images/pethouse.png",
                    title: "Hayvan Evleri",
                    description: """
Sokak hayvanları için yerleştirilmiş mor kulübeler, haritada ev simgesiyle gösterilir.

Her evde:
• Hayvan türü (kedi/köpek),
• Lokasyon ve fotoğraf yer alır.

Uygunsuz içerikleri 'Bildir' butonuyla iletebilirsiniz.
""",
                  ),

                  _buildInfoCardWithTwoIcons(
                    iconPath1: "assets/images/pet-food1.png",
                    iconPath2: "assets/images/pethouse2.png",
                    title: "Mama Kabı / Hayvan Evi Ekleme",
                    description: """
Sağ alttaki butonlardan:

🍖 Mama Kabı Ekle → İlgili ikona basarak mama noktası eklersiniz.

🏠 Hayvan Evi Ekle → İlgili ikona tıklayıp konum ve tür seçerek yeni ev oluşturabilirsiniz.

Konum otomatik alınır, tür ve görsel istenir.
""",
                  ),

                  _buildInfoCardWithTwoIcons(
                    iconPath1: "assets/images/cat.png",
                    iconPath2: "assets/images/dog.png",
                    title: "Kedi / Köpek Filtreleme",
                    description: """
Sağ üstteki 🐱 ve 🐶 ikonlarıyla sadece belirli türe ait noktaları görebilirsiniz.

Aynı butona tekrar tıklarsanız filtre kaldırılır.
""",
                  ),

                  _buildInfoCard(
                    iconPath: "assets/images/acildurum.png",
                    title: "Acil Durum Bildir",
                    description: """
Sol alttaki kırmızı 'Acil Durum' butonuyla belediyelere anında bildirim yapabilirsiniz.

Girdiğiniz açıklama, eklediğiniz fotoğraf ve bulunduğunuz konum ilgili birimlere kısa sürede iletilmeye çalışılır.
""",
                    iconSize: 60,
                  ),

                  _buildInfoCard(
                    iconPath: "assets/images/veterinary.png",
                    title: "Veterinerler",
                    description: """
Sağdaki veteriner ikonuna dokunarak size en yakın veteriner kliniklerini görebilirsiniz.

Harita üzerinden konumları listelenir, yön tarifi ve iletişim bilgileri sağlanır.
""",
                  ),

                  _buildInfoCard(
                    iconPath: "assets/images/animal-shelter.png",
                    title: "Hayvan Barınakları",
                    description: """
Sağdaki barınak ikonuna tıklayarak bulunduğunuz şehirdeki barınakları görebilirsiniz.

Barınakların:
• Adı, fotoğrafları ve adresi,
• Toplam hayvan sayısı gösterilir.

Detay sayfasında barınaktaki hayvanları inceleyebilir, iletişim kurabilirsiniz.
""",
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      "DoldurKabı, patili dostlarımızın sesi, eli, yüreği.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      "Bir kap mama, bir yürek dokunuşu… DoldurKabı her can için burada 🐕‍🦺🐈",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      "DoldurKabı ile artık sokaktaki dostlarımız yalnız değil \n🐶🐱",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

// ✅ DİNAMİK ALT BOŞLUK
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 1),                ]),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildInfoCardWithTwoIcons({
    required String iconPath1,
    required String iconPath2,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconPath1, width: 40, height: 40),
              const SizedBox(width: 20),
              Image.asset(iconPath2, width: 37, height: 37),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.left,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoCard({
    required String iconPath,
    required String title,
    required String description,
    double iconSize = 46, // 🆕 varsayılan değer
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.left,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }



}
