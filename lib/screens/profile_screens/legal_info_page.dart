import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LegalInfoPage extends StatelessWidget {
  const LegalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF8FF), // açık lila/beyaz arası
        appBar: AppBar(
          backgroundColor: const Color(0xFF9346A1), // DoldurKabı moru
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "Yasal Bilgiler",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFEBDBF3),
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Kullanım"),
              Tab(text: "Gizlilik"),
              Tab(text: "Aydınlatma"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TermsTab(),
            PrivacyTab(),
            NoticeTab(),
          ],
        ),
      ),
    );
  }
}

// 📦 Ortak içerik düzeni
Widget _scrollWrapper(List<Widget> children) {
  return ListView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    children: children,
  );
}

Widget _section(String title, String content) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Color(0xFFE5D0EE)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class TermsTab extends StatelessWidget {
  const TermsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _scrollWrapper([
      _section("1. Genel Hükümler", "DoldurKabı, kullanıcıların sokak hayvanlarına destek olmalarını kolaylaştırmak için geliştirilmiş bir mobil platformdur. Uygulama üzerinden mama kapları eklenebilir, hayvan evleri yerleştirilebilir, ilanlar paylaşılabilir ve toplulukla etkileşim kurulabilir."),
      _section("2. Kapsam ve Amaç", "Uygulamanın temel amacı, sahipsiz hayvanların beslenme, barınma ve sahiplenme süreçlerine katkı sunmak ve bu süreçleri dijital ortamda kolaylaştırmaktır. Aynı zamanda kullanıcılar arasında bilinç oluşturmayı hedefler."),
      _section("3. Kullanıcı Sorumlulukları", "Kullanıcılar, uygulamayı yalnızca yasalara uygun ve etik değerlere saygılı şekilde kullanmalıdır. Hayvanlara zarar verecek eylemlerden, yanıltıcı içeriklerden ve kötü niyetli davranışlardan kaçınılmalıdır."),
      _section("4. Paylaşım Kuralları", "Paylaşılan tüm ilan, yorum ve içeriklerin gerçek, güncel ve saygılı olması beklenmektedir. Nefret söylemi, şiddet, cinsel içerik, spam veya yanıltıcı bilgiler paylaşmak yasaktır."),
      _section("5. Hesap Kullanımı", "Her kullanıcı kendi hesabının güvenliğinden sorumludur. Şifrelerin güvenli şekilde saklanması ve başkalarıyla paylaşılmaması kullanıcı yükümlülüğündedir."),
      _section("6. Veri Toplama ve Koruma", "Uygulama, kullanıcıların kişisel bilgilerini gizlilik politikası çerçevesinde toplar ve saklar. Bu veriler, hizmetin iyileştirilmesi dışında hiçbir amaçla kullanılmaz."),
      _section("7. Teknik Kesintiler ve Güncellemeler", "Uygulamada zaman zaman bakım, güncelleme veya beklenmeyen teknik sorunlar nedeniyle geçici erişim problemleri yaşanabilir. Kullanıcılar bu durumları anlayışla karşılamayı kabul eder."),
      _section("8. Üçüncü Taraf Bağlantılar", "Uygulama içinde farklı sitelere veya kaynaklara yönlendirme yapılabilir. Bu sitelerin içeriklerinden DoldurKabı sorumlu değildir."),
      _section("9. Moderasyon ve Askıya Alma", "Kuralları ihlal eden kullanıcıların içerikleri silinebilir, hesapları askıya alınabilir veya tamamen kapatılabilir. Bu işlemler yönetim ekibi takdirine bağlıdır."),
      _section("10. Değişiklik Hakkı", "DoldurKabı, kullanım şartlarını önceden haber vermeksizin güncelleme hakkını saklı tutar. Güncel şartlar uygulamada yayımlandığı anda geçerli sayılır."),
      _section("11. Sorumluluk Reddi", "Uygulama, kullanıcılar tarafından yapılan hayvan beslemeleri veya diğer fiziksel etkileşimler nedeniyle doğabilecek herhangi bir doğrudan ya da dolaylı sorumluluğu üstlenmez."),
      _section("12. İletişim", "Her türlü öneri, şikayet ve geri bildirim için 'Bize Ulaşın' sayfasını kullanabilirsiniz. Ekip en kısa sürede dönüş sağlayacaktır."),
    ]);
  }
}


class PrivacyTab extends StatelessWidget {
  const PrivacyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _scrollWrapper([
      _section("1. Verilerin Toplanması", "DoldurKabı, kullanıcı deneyimini geliştirmek amacıyla ad, soyad, e-posta, profil fotoğrafı, cihaz bilgileri, konum verileri ve kullanım alışkanlıkları gibi bilgileri toplayabilir."),
      _section("2. Verilerin İşlenme Amaçları", "Toplanan veriler; kullanıcı etkileşimlerini kişiselleştirme, istatistiksel analiz yapma, hizmetleri geliştirme ve kullanıcı taleplerine dönüş sağlama amacıyla kullanılır."),
      _section("3. Verilerin Saklanması", "Kişisel veriler, yalnızca hizmet sağlamak için gerekli olduğu sürece saklanır. Veriler Firebase gibi güvenilir altyapılar üzerinde korunur ve düzenli olarak yedeklenir."),
      _section("4. Verilerin Güvenliği", "Veriler yetkisiz erişim, kayıp veya kötüye kullanım gibi risklere karşı şifrelenmiş şekilde saklanır. Gerekli güvenlik önlemleri alınarak veri bütünlüğü sağlanır."),
      _section("5. Verilerin Paylaşımı", "Kullanıcı verileri, üçüncü taraflarla ancak açık rıza ile paylaşılır. Bunun dışında yalnızca yasal zorunluluk durumlarında ilgili makamlara iletilebilir."),
      _section("6. Kullanıcı Hakları", "Kullanıcılar, kendilerine ait verileri görüntüleme, düzeltme, silme ve işlemeye itiraz etme hakkına sahiptir. Bu haklar, uygulama içi iletişim kanalları üzerinden kullanılabilir."),
      _section("7. Çerez ve Takip Teknolojileri", "Uygulama, bazı hizmetleri iyileştirmek ve davranış analizi yapmak için çerez ve benzeri takip teknolojilerini kullanabilir. Kullanıcı dilerse bu izlemeyi sınırlayabilir."),
      _section("8. Politika Güncellemeleri", "Gizlilik politikası zaman içinde değiştirilebilir. Önemli değişiklikler uygulama içinde bildirilecek ve güncellenmiş metin kullanıcıya sunulacaktır."),
    ]);
  }
}


class NoticeTab extends StatelessWidget {
  const NoticeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _scrollWrapper([
      _section("1. Toplanan Veriler", "Ad, soyad, e-posta adresi, kullanıcı kimliği, cihaz modeli, IP adresi, konum bilgisi ve uygulama içi etkileşimler gibi çeşitli kişisel veriler toplanabilir."),
      _section("2. Toplama Yöntemi", "Veriler, uygulamaya kayıt sırasında, kullanıcı hareketleriyle ve hizmet kullanımı esnasında otomatik ya da kullanıcı beyanıyla elde edilir."),
      _section("3. Verilerin Kullanım Amaçları", "Toplanan veriler, hizmetin sağlanması, kullanıcı deneyiminin geliştirilmesi, sistem güvenliğinin sağlanması ve istatistiksel analizler için kullanılır."),
      _section("4. Veri Güvenliği", "Kişisel veriler güvenli sunucularda saklanır ve yalnızca yetkili kişilerce erişilebilir. Sistemler, olası güvenlik ihlallerine karşı düzenli olarak denetlenir."),
      _section("5. Hukuki Dayanak", "Veri işleme faaliyetleri, KVKK başta olmak üzere yürürlükteki yasal düzenlemelere ve kullanıcının açık rızasına dayanmaktadır."),
      _section("6. Kullanıcı Hakları", "Kullanıcılar; verilerine erişme, düzeltme, silme, işlenmesini durdurma ve itiraz etme haklarına sahiptir. Bu haklar, uygulama içinden veya destek ekibine başvurarak kullanılabilir."),
      _section("7. Veri Paylaşımı", "Veriler üçüncü kişilerle yalnızca yasal yükümlülükler kapsamında veya açık onayınızla paylaşılır. Ticari amaçla paylaşım yapılmaz."),
      _section("8. Güncellemeler ve İletişim", "Bu metin zamanla güncellenebilir. Güncellemeler uygulama üzerinden duyurulur. Herhangi bir soru için 'Bize Ulaşın' sayfası üzerinden iletişime geçebilirsiniz."),
    ]);
  }
}
