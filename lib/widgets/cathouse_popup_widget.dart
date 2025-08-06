import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CathousePopupWidget extends StatelessWidget {
  final String titleText;
  final String leadingEmoji;
  final String? imageUrl;
  final Timestamp? timestamp;
  final VoidCallback onReportPressed;
  final VoidCallback? onImageTap;

  const CathousePopupWidget({
    super.key,
    required this.titleText,
    required this.leadingEmoji,
    required this.imageUrl,
    required this.timestamp,
    required this.onReportPressed,
    this.onImageTap,
  });

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}.${date.month}.${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, spreadRadius: 2)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Row(
            children: [
              Text(leadingEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onReportPressed,
                child: const Icon(Icons.more_vert, color: Colors.black54),
              ),
            ],
          ),

          // Tarih
          if (timestamp != null)
            Text(
              "📅 Eklenme: ${_formatTimestamp(timestamp!)}",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 10),

          // Görsel
          if (imageUrl != null && imageUrl!.isNotEmpty)
            GestureDetector(
              onTap: onImageTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  width: 200,
                  height: 110,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 110,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
