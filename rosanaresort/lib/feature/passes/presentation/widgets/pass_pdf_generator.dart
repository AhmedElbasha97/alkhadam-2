import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../../data/models/pass_model.dart';

class PassPdfGenerator {
  /// Generates a PDF for the given [PassModel] and opens it with the device viewer.
  static Future<void> generateAndOpen(PassModel pass) async {
    final pdf = pw.Document();

    // ── Load Arabic font ──────────────
    pw.Font? arabicFont;

    try {
      final fontData = await rootBundle.load('assets/arabic-font/Cairo-Medium.ttf');
      arabicFont = pw.Font.ttf(fontData);
    } catch (e) {
      print('Error loading font: $e'); // Helpful for debugging
    }

    // ── Load pass photo ───────────────────────────────────────────────────
    pw.ImageProvider? personImage;
    try {
      final response = await http.get(Uri.parse(pass.img));
      if (response.statusCode == 200) {
        personImage = pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {}

    // ── QR code bytes ───────
    Uint8List? qrBytes;
    try {
      final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${pass.qrcode}';
      final qrRes = await http.get(Uri.parse(qrUrl));
      if (qrRes.statusCode == 200) qrBytes = qrRes.bodyBytes;
    } catch (_) {}

    final baseFont = arabicFont ?? pw.Font.helvetica();
    final boldFont = arabicFont ?? pw.Font.helveticaBold();

    final teal = PdfColor.fromHex('#0E8982');
    final gold = PdfColor.fromHex('#CF9F1A');
    final textDark = PdfColor.fromHex('#1A1A2E');
    final textMuted = PdfColor.fromHex('#6F6F6F');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // ── Header bar ──────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                color: teal,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Rosana Resort',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 22,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'تصريح دخول',
                          textDirection: pw.TextDirection.rtl, // <-- ADDED
                          style: pw.TextStyle(
                            font: baseFont,
                            fontSize: 14,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: gold,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        pass.caption,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 13,
                          color: PdfColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              pw.Expanded(
                child: pw.Container(
                  width: double.infinity,
                  color: PdfColors.white,
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left: person info + dates
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Person photo
                            if (personImage != null)
                              pw.ClipRRect(
                                horizontalRadius: 12,
                                verticalRadius: 12,
                                child: pw.Image(personImage,
                                    width: 110, height: 110, fit: pw.BoxFit.cover),
                              ),
                            pw.SizedBox(height: 20),

                            _pdfLabel('الاسم', boldFont, teal),
                            _pdfValue(pass.name, baseFont, textDark),
                            pw.SizedBox(height: 14),

                            _pdfLabel('رقم التصريح', boldFont, teal),
                            _pdfValue(pass.caption, baseFont, textDark), // Kept LTR if it's alphanumeric, change if it contains Arabic
                            pw.SizedBox(height: 14),

                            _pdfLabel('تاريخ البداية', boldFont, teal),
                            _pdfValue(pass.dateFrom, baseFont, textDark),
                            pw.SizedBox(height: 14),

                            _pdfLabel('تاريخ الانتهاء', boldFont, teal),
                            _pdfValue(pass.dateTo, baseFont, textDark),
                            pw.SizedBox(height: 14),

                            _pdfLabel('الحالة', boldFont, teal),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: pw.BoxDecoration(
                                color: pass.isActive ? teal : PdfColor.fromHex('#BDBDBD'),
                                borderRadius: pw.BorderRadius.circular(20),
                              ),
                              child: pw.Text(
                                pass.isActive ? 'فعّال' : 'منتهي',
                                textDirection: pw.TextDirection.rtl, // <-- ADDED
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 12,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(width: 40),

                      // Right: QR code
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          if (qrBytes != null) ...[
                            pw.Container(
                              padding: const pw.EdgeInsets.all(12),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: teal.shade(.3), width: 2),
                                borderRadius: pw.BorderRadius.circular(12),
                              ),
                              child: pw.Image(pw.MemoryImage(qrBytes), width: 160, height: 160),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'امسح للتحقق',
                              textDirection: pw.TextDirection.rtl, // <-- ADDED
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer ───────────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                color: PdfColor.fromHex('#F5F5F5'),
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'rosana-resort.com',
                      style: pw.TextStyle(font: baseFont, fontSize: 11, color: textMuted),
                    ),
                    pw.Text(
                      'QR: ${pass.qrcode}',
                      style: pw.TextStyle(font: baseFont, fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // ── Save & open ──────────────────────────────────────────────────────────
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pass_${pass.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _pdfLabel(String text, pw.Font font, PdfColor color) {
    return pw.Text(
      text,
      textDirection: pw.TextDirection.rtl, // <-- ADDED
      style: pw.TextStyle(font: font, fontSize: 11, color: color),
    );
  }

  static pw.Widget _pdfValue(String text, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl, // <-- ADDED (Ensures Arabic names/data render correctly)
        style: pw.TextStyle(font: font, fontSize: 15, color: color),
      ),
    );
  }
}