import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingPointPopupWidget extends StatelessWidget {
  final bool isCat;
  final bool isFilling;
  final bool isFilled;
  final String titleText;
  final String leadingEmoji;
  final String? imageUrl;
  final Timestamp? timestamp;
  final VoidCallback onFillPressed;
  final VoidCallback onReportPressed;
  final VoidCallback? onImageTap;

  const FeedingPointPopupWidget({
    super.key,
    required this.isCat,
    required this.isFilling,
    required this.isFilled,
    required this.titleText,
    required this.leadingEmoji,
    required this.imageUrl,
    required this.timestamp,
    required this.onFillPressed,
    required this.onReportPressed,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded( // 🧠 Metni sığdırmak için bu şart
                child: Row(
                  children: [
                    Text(leadingEmoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 6),
                    Flexible( // 🧠 Metin çok uzun olursa sarsın
                      child: Text(
                        titleText,
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 24, color: Colors.black54),
                onPressed: onReportPressed,
              ),
            ],
          ),

          const SizedBox(height: 6), // 👈 Bunu ekle


          // Doldurma durumları
          AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            child: isFilling
                ? const Text(
              "⏳ Dolduruluyor...✅",
              key: ValueKey(2),
              style: TextStyle(fontSize: 14, color: Colors.green),
            )
                : isFilled
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                  // Yeni: Eğer 3 saatten eskiyse uyarı göster
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            _buildFillStatusText(timestamp!),
                            style: TextStyle(
                              color: _isFilledRecently(timestamp!) ? Colors.green : Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                  ),

                if (_shouldShowCountdown(timestamp!))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _buildFillingProgressBar(timestamp!, isCat),
                  ),


                const SizedBox(height: 8),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: onImageTap,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl!,
                          width: 160,
                          height: 80,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const SizedBox(
                            width: 160,
                            height: 100,
                            child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.purple,
                                  strokeWidth: 4,
                                )),
                          ),
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
              ],
            )
                : const Text(
              "🔴 Henüz Doldurulmadı",
              key: ValueKey(4),
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),

          const SizedBox(height: 8),

          // Doldur Butonu
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.purple.shade600, width: 2),
              ),
              elevation: 4,
              shadowColor: Colors.purple.withOpacity(0.5),
            ),
            onPressed: onFillPressed,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Doldur",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 8),
                FaIcon(FontAwesomeIcons.paw, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowCountdown(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());
    return diff.inHours < 3;
  }

  bool _isFilledRecently(Timestamp t) => DateTime.now().difference(t.toDate()).inHours < 3;

  String _buildFillStatusText(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (!_isFilledRecently(timestamp)) {
      if (days >= 1) {
        return "🔴 Muhtemelen boş – Yaklaşık $days gün önce doldurulmuştu.";
      } else if (hours >= 1) {
        return "🔴 Muhtemelen boş – $hours saat önce doldurulmuştu.";
      } else {
        return "🔴 Muhtemelen boş – $minutes dakika önce doldurulmuştu.";
      }
    }

    if (diff.inMinutes < 5) {
      return "🟢 Az önce dolduruldu.";
    }

    if (diff.inHours >= 1) {
      return "🟢 ${diff.inHours} saat ${diff.inMinutes % 60} dakika önce dolduruldu.";
    } else {
      return "🟢 ${diff.inMinutes} dakika önce dolduruldu.";
    }
  }


}

Widget _buildFillingProgressBar(Timestamp timestamp, bool isCat) {
  final elapsed = DateTime.now().difference(timestamp.toDate());
  final total = const Duration(hours: 3);
  double progress = (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);
  double fillLevel = 1 - progress;
  int percentage = (fillLevel * 100).round();

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: fillLevel),
    duration: const Duration(seconds: 1),
    builder: (context, animatedFill, _) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            isCat ? "assets/images/catfoodbos.png" : "assets/images/dogfoodbos.png",
            width: 34,
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 140,
              height: 18,
              color: Colors.grey.shade300,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animatedFill,
                    child: Container(
                      decoration: BoxDecoration(
                        color: animatedFill > 0.66
                            ? Colors.green
                            : animatedFill > 0.33
                            ? Colors.orange
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "%$percentage dolu",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            isCat ? "assets/images/catfood.png" : "assets/images/dogfood.png",
            width: 34,
          ),
        ],
      );
    },
  );
}

