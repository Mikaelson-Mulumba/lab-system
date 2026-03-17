import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'header_section.dart';
import 'patient_info_table.dart';
import '../db/database_helper.dart';

class UrinalysisPdfPreviewPage extends StatefulWidget {
  final Map<String, dynamic>? patient;
  final List<String> specimens;
  final List<String> investigations;
  final List<Map<String, dynamic>> results;
  final Map<String, String>? payment; // ✅ Payment info
  final String currentUser; // ✅ logged-in user

  const UrinalysisPdfPreviewPage({
    super.key,
    this.patient,
    this.specimens = const [],
    this.investigations = const [],
    this.results = const [],
    this.payment,
    required this.currentUser,
  });

  @override
  State<UrinalysisPdfPreviewPage> createState() =>
      _UrinalysisPdfPreviewPageState();
}

class _UrinalysisPdfPreviewPageState extends State<UrinalysisPdfPreviewPage> {
  double _zoom = 1.0;

  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();
    final logo = await imageFromAssetBundle('assets/images/lab-logo.png');

    final robotoRegular = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Roboto-Regular.ttf"),
    );
    final robotoBold = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Roboto-Bold.ttf"),
    );
    final robotoItalic = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Roboto-Italic.ttf"),
    );

    // Group results by category
    final Map<String, List<Map<String, dynamic>>> groupedResults = {};
    for (var r in widget.results) {
      final category = r['category'] ?? 'Uncategorized';
      groupedResults.putIfAbsent(category, () => []).add(r);
    }

    // ✅ Page 1: Results
pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (pw.Context context) => [
      HeaderSection.build(
        logo,
        robotoRegular: robotoRegular,
        robotoBold: robotoBold,
        robotoItalic: robotoItalic,
      ),
      pw.Divider(),
      PatientInfoTable.build(
        widget.patient,
        specimens: widget.specimens,
        investigations: widget.investigations,
        robotoRegular: robotoRegular,
        robotoBold: robotoBold,
      ),
      pw.SizedBox(height: 14),
      pw.Center(child: pw.Text('URINALYSIS REPORT',
          style: pw.TextStyle(font: robotoBold, fontSize: 9))),
      pw.SizedBox(height: 10),

      // Results + Comments
      for (var entry in groupedResults.entries) ...[
        pw.Center(child: pw.Text(entry.key,
            style: pw.TextStyle(font: robotoBold, fontSize: 9))),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Test Name', 'Result', 'Normal Range', 'Unit'],
          data: entry.value.map((r) => [
            r['name'] ?? '',
            r['result'] ?? '',
            r['reference_range'] ?? '',
            r['unit'] ?? '',
          ]).toList(),
          headerStyle: pw.TextStyle(font: robotoBold),
          cellStyle: pw.TextStyle(font: robotoRegular, fontSize: 9),
          border: pw.TableBorder.all(width: 0.5),
        ),

        if (entry.value.any((r) => (r['comment'] ?? '').isNotEmpty)) ...[
          pw.SizedBox(height: 8),
          pw.Text('Comments:', style: pw.TextStyle(font: robotoBold, fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text(
            entry.value
                .map((r) => r['comment'])
                .where((c) => c != null && c.isNotEmpty)
                .join("\n"),
            style: pw.TextStyle(font: robotoItalic, fontSize: 9),
          ),
        ],
        pw.SizedBox(height: 16),
      ],

      pw.SizedBox(height: 20),
      // Signatures
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(children: [
            pw.Text('Lab Technician: ${widget.currentUser}',
                style: pw.TextStyle(font: robotoRegular, fontSize: 10)),
            pw.SizedBox(height: 20),
            pw.Text('Signature: ____________________',
                style: pw.TextStyle(font: robotoItalic, fontSize: 9)),
          ]),
          pw.Column(children: [
            pw.Text('Approved By: ${widget.currentUser}',
                style: pw.TextStyle(font: robotoRegular, fontSize: 10)),
            pw.SizedBox(height: 20),
            pw.Text('Signature: ____________________',
                style: pw.TextStyle(font: robotoItalic, fontSize: 9)),
          ]),
        ],
      ),

      // ✅ Tagline at bottom of Page 1
      pw.SizedBox(height: 12),
      pw.Center(
        child: pw.Text(
          'Your Trusted Diagnostic Partner',
          style: pw.TextStyle(font: robotoItalic, fontSize: 9, color: PdfColors.blue),
        ),
      ),
    ],
  ),
);

// ✅ Page 2: Payment Details
pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (pw.Context context) => [
      HeaderSection.build(
        logo,
        robotoRegular: robotoRegular,
        robotoBold: robotoBold,
        robotoItalic: robotoItalic,
      ),
      pw.Divider(),
      PatientInfoTable.build(
        widget.patient,
        specimens: widget.specimens,
        investigations: widget.investigations,
        robotoRegular: robotoRegular,
        robotoBold: robotoBold,
      ),
      pw.SizedBox(height: 16),
      pw.Center(child: pw.Text('PAYMENT DETAILS',
          style: pw.TextStyle(font: robotoBold, fontSize: 12))),
      pw.SizedBox(height: 12),

      if (widget.payment != null) ...[
        pw.Text('Amount Paid: UGX ${widget.payment!['amount']}',
            style: pw.TextStyle(font: robotoRegular, fontSize: 11)),
        pw.Text('Paid By: ${widget.payment!['paid_by']}',
            style: pw.TextStyle(font: robotoRegular, fontSize: 11)),
        pw.Text('Payment Date: ${DateTime.now().toLocal().toString().split(" ").first}',
            style: pw.TextStyle(font: robotoRegular, fontSize: 11)),
      ],

      pw.SizedBox(height: 20),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(children: [
            pw.Text('Printed By: ${widget.currentUser}',
                style: pw.TextStyle(font: robotoRegular, fontSize: 11)),
            pw.SizedBox(height: 20),
            pw.Text('Signature: ____________________',
                style: pw.TextStyle(font: robotoItalic, fontSize: 9)),
          ]),
          pw.Column(children: [
            pw.Text('Lab Technician: ${widget.currentUser}',
                style: pw.TextStyle(font: robotoRegular, fontSize: 11)),
            pw.SizedBox(height: 20),
            pw.Text('Signature: ____________________',
                style: pw.TextStyle(font: robotoItalic, fontSize: 9)),
          ]),
          pw.Column(children: [
            pw.Text('Approved By: ${widget.currentUser}',
                style: pw.TextStyle(font: robotoRegular, fontSize: 11)),
            pw.SizedBox(height: 20),
            pw.Text('Signature: ____________________',
                style: pw.TextStyle(font: robotoItalic, fontSize: 9)),
          ]),
        ],
      ),

      // ✅ Tagline at bottom of Page 2
      pw.SizedBox(height: 12),
      pw.Center(
        child: pw.Text(
          'Your Trusted Diagnostic Partner',
          style: pw.TextStyle(font: robotoItalic, fontSize: 9, color: PdfColors.blue),
        ),
      ),
    ],
  ),
);

    return pdf;
  }

  Future<void> _savePdfToDatabase() async {
    final pdf = await _buildPdf();
    final bytes = await pdf.save();

    final db = await DatabaseHelper.instance.database;
    await db.insert('reports', {
      'patient_id': widget.patient?['id'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
      'pdf_data': bytes,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Urinalysis report saved to database')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Urinalysis PDF Preview')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _zoom = (_zoom - 0.1).clamp(0.5, 3.0);
                  });
                },
              ),
              Text('${(_zoom * 100).round()}%'),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _zoom = (_zoom + 0.1).clamp(0.5, 3.0);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _zoom = 1.0;
                  });
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Report'),
                onPressed: _savePdfToDatabase,
              ),
            ],
          ),
          Expanded(
            child: Transform.scale(
              scale: _zoom,
              alignment: Alignment.topCenter,
              child: PdfPreview(
                build: (format) async => (await _buildPdf()).save(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
