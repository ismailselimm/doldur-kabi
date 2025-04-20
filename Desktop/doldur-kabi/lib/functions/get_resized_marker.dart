
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> getResizedMarker(String imagePath, int width, int height) async {
  final ByteData data = await rootBundle.load(imagePath);
  final Uint8List list = data.buffer.asUint8List();
  final ui.Codec codec = await ui.instantiateImageCodec(list, targetWidth: width, targetHeight: height);
  final ui.FrameInfo fi = await codec.getNextFrame();
  final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List resizedBytes = byteData!.buffer.asUint8List();
  return BitmapDescriptor.fromBytes(resizedBytes);
}