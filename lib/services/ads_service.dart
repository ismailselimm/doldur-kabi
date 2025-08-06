import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String imageUrl;
  final String? url;

  BannerModel({required this.imageUrl, this.url});
}

class AdsService {
  static Future<List<BannerModel>> fetchBanners() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("banners")
        .orderBy("order")
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BannerModel(
        imageUrl: data['imageUrl'] ?? '',
        url: data['url'], // opsiyonel olabilir
      );
    }).toList();
  }
}
