import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class HeaderSection {
  static pw.Widget build(
    pw.ImageProvider logo, {
    required pw.Font robotoRegular,
    required pw.Font robotoBold,
    required pw.Font robotoItalic,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo on the left
        pw.Container(
          width: 70,
          height: 70,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),

        // Lab details on the right
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Lab name styled with Roboto Bold
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'POWERS ',
                    style: pw.TextStyle(
                      font: robotoBold,
                      fontSize: 12,
                      color: const PdfColor.fromInt(0xFF4169E1),
                    ),
                  ),
                  pw.TextSpan(
                    text: 'CLINICAL ',
                    style: pw.TextStyle(
                      font: robotoBold,
                      color: const PdfColor.fromInt(0xFF4169E1),
                    ),
                  ),
                  pw.TextSpan(
                    text: 'LABORATORIES',
                    style: pw.TextStyle(
                      font: robotoBold,
                      fontSize: 12,
                      color: const PdfColor.fromInt(0xFF4169E1),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 4),

            pw.Text(
              'Iganga, Old Kaliro Rd, behind Hotel Continental',
              style: pw.TextStyle(font: robotoRegular, fontSize: 9, color: PdfColors.black),
            ),
            pw.Text(
              'Tel: +256 (0) 764 440 045 / +256 (0) 741 293 424',
              style: pw.TextStyle(font: robotoRegular, fontSize: 9, color: PdfColors.blueAccent400),
            ),
            pw.Text(
              'Email: powerslab@gmail.com',
              style: pw.TextStyle(font: robotoRegular, fontSize: 9, color: PdfColors.black),
            ),

            pw.SizedBox(height: 4),

            // Tagline
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Accurate ',
                    style: pw.TextStyle(
                      font: robotoBold,
                      fontSize: 10,
                      color: const PdfColor.fromInt(0xFF4169E1),
                    ),
                  ),
                  pw.TextSpan(
                    text: '| Caring ',
                    style: pw.TextStyle(
                      font: robotoBold,
                      fontSize: 10,
                      color: const PdfColor.fromInt(0xFF4169E1),
                    ),
                  ),
                  pw.TextSpan(
                    text: '| Instant',
                    style: pw.TextStyle(
                      font: robotoBold,
                      fontSize: 10,
                      color: const PdfColor.fromInt(0xFF4169E1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
