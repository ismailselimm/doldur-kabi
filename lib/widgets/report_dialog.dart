import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showReportDialog(
    BuildContext context, {
      required String targetType,
      required String targetId,
      required String targetUserEmail,
      required String targetTitle,
      String? relatedPostId, // 👈 YENİ parametre

    }) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  String selectedReason = '';
  String description = '';
  bool isLoading = false;

  final List<String> reportReasons = [
    "Spam / Reklam",
    "Uygunsuz içerik",
    "Yanıltıcı bilgi",
    "Hakaret / Taciz",
    "Hayvan istismarı",
    "Sahte hesap / içerik",
    "Diğer",
  ];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Bu içeriği neden bildiriyorsun?",
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason.isNotEmpty ? selectedReason : null,
                  items: reportReasons.map((reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason, style: GoogleFonts.poppins(fontSize: 14.5)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedReason = value ?? ''),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    hintText: "Bir sebep seçin",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (val) => description = val,
                  maxLines: 4,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: "Açıklama (isteğe bağlı)",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading || selectedReason.isEmpty
                        ? null
                        : () async {
                      if (targetUserEmail.isEmpty || targetId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Eksik veri. Kayıt gönderilemedi.", style: GoogleFonts.poppins()),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        await FirebaseFirestore.instance.collection('complaints').add({
                          'targetType': targetType,
                          'targetId': targetId,
                          'targetUserEmail': targetUserEmail,
                          'targetTitle': targetTitle,
                          'reporterEmail': currentUser.email,
                          'reason': selectedReason,
                          'description': description.trim(),
                          'createdAt': Timestamp.now(),
                          if (relatedPostId != null) 'relatedPostId': relatedPostId, // 👈 sadece varsa ekle

                        });

                        if (context.mounted) Navigator.pop(context);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"$selectedReason" olarak bildirildi.',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              backgroundColor: Colors.deepPurple,
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Hata oluştu: $e", style: GoogleFonts.poppins()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) setState(() => isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Bildir", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15.5)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
