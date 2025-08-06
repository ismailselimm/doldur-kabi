import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ShimmerAvatar({super.key, required this.imageUrl, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: precacheImage(NetworkImage(imageUrl), context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(imageUrl),
          );
        } else {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[300],
            ),
          );
        }
      },
    );
  }
}
