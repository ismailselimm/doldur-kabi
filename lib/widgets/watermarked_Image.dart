import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WatermarkedImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;

  const WatermarkedImage({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: width,
                  height: height,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Transform.rotate(
              angle: 0,
              child: Text(
                'DoldurKabı',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  shadows: const [
                    Shadow(color: Colors.black54, offset: Offset(0.1, 0.1), blurRadius: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
