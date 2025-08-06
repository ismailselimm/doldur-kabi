import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

class AdoptionPosterScreen extends StatefulWidget {
  final String imageUrl;
  final String description;
  final String animalType;
  final String city;
  final DateTime? date;
  final String ownerName;
  final String docId;

  const AdoptionPosterScreen({
    super.key,
    required this.imageUrl,
    required this.description,
    required this.animalType,
    required this.city,
    required this.date,
    required this.ownerName,
    required this.docId,
  });

  @override
  State<AdoptionPosterScreen> createState() => _AdoptionPosterScreenState();
}

class _AdoptionPosterScreenState extends State<AdoptionPosterScreen> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _saveAsImage() async {
    try {
      final boundary = _globalKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Galeri izni iste
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        _showCustomSnackbar("Galeri izni verilmedi ❌", icon: FontAwesomeIcons.circleExclamation, bgColor: Colors.redAccent);
        return;
      }

      // Geçici dosya yaz
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/doldurkabi_afis_${widget.docId}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Galeriye kaydet
      final result = await PhotoManager.editor.saveImage(
        pngBytes,
        title: "doldurkabi_afis_${widget.docId}",
        filename: '',
      );

      if (result != null) {
        _showCustomSnackbar("Galeriye kaydedildi 📸", icon: FontAwesomeIcons.circleCheck, bgColor: Colors.green);
      } else {
        _showCustomSnackbar("Kaydedilemedi ❌", icon: FontAwesomeIcons.circleExclamation, bgColor: Colors.orange);
      }
    } catch (e) {
      _showCustomSnackbar("Hata: $e", icon: FontAwesomeIcons.triangleExclamation, bgColor: Colors.red);
    }
  }

  Future<void> _saveAsPdf() async {
    try {
      final boundary = _globalKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) =>
              pw.Center(child: pw.Image(imageProvider)),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/doldurkabi_afis_${widget.docId}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // iOS'ta paylaş menüsünü aç
      if (Platform.isIOS) {
        await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')]);
      }
    } catch (e) {
      _showCustomSnackbar("Hata: $e", icon: FontAwesomeIcons.triangleExclamation, bgColor: Colors.red);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Tarih Yok";
    return DateFormat('dd.MM.yyyy').format(date);
  }

  void _showCustomSnackbar(String message, {IconData? icon, Color? bgColor}) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: bgColor ?? const Color(0xFF9346A1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FaIcon(icon, size: 20, color: Colors.white),
            ),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: Text(
          "İlan Afişi",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Fotoğraf Kaydet",
            onPressed: _saveAsImage,
            icon: const FaIcon(FontAwesomeIcons.image, size: 20, color: Color(0xFF9346A1)),
          ),
          IconButton(
            tooltip: "PDF Olarak Kaydet",
            onPressed: _saveAsPdf,
            icon: const FaIcon(FontAwesomeIcons.filePdf, size: 20, color: Color(0xFF9346A1)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Başlık
                  Text(
                    "🐾 YENİ YUVASINI ARIYOR!",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9346A1),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // İlan görseli
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 👤 İlan Sahibi
                  Text(
                    "${widget.ownerName}",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 📍 Şehir ve 📅 Tarih (yan yana)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "📍 ${widget.city}",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "📅 ${_formatDate(widget.date)}",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Açıklama
                  Text(
                    '"${widget.description}"',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 20),

                  // Dipnot kutusu
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9346A1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 🐾 Logo (sol)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 📄 Yazılar (sağ)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Bu ilan DoldurKabı mobil uygulamasında yayınlanmıştır. Daha fazlası için:",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "www.doldurkabi.com",
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF9346A1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            ),
          ),
        ),
      ),
    );
  }

}
