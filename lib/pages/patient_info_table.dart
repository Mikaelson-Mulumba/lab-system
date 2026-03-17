import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart'; // for formatting DateTime

class PatientInfoTable {
  static pw.Widget build(
    Map<String, dynamic>? patient, {
    List<String> specimens = const [],
    List<String> investigations = const [],
    required pw.Font robotoRegular,
    required pw.Font robotoBold,
  }) {
    // ✅ Get current date/time from PC
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Patient Information',
          style: pw.TextStyle(
            font: robotoBold,
            fontSize: 12,
          ),
        ),
        pw.SizedBox(height: 6),

        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // ✅ Show patient_code instead of numeric id
            _row('Patient Code', patient?['patient_code']?.toString() ?? 'N/A',
                'Tested At', formattedDateTime,
                robotoRegular, robotoBold),
            _row('First Name', patient?['first_name'] ?? 'N/A',
                'Second Name', patient?['second_name'] ?? 'N/A',
                robotoRegular, robotoBold),
            _row('Age', patient?['age']?.toString() ?? 'N/A',
                'Gender', patient?['gender'] ?? 'N/A',
                robotoRegular, robotoBold),
            _row('Specimen',
                specimens.isNotEmpty ? specimens.join(', ') : 'N/A',
                'Investigations',
                investigations.isNotEmpty ? investigations.join(', ') : 'N/A',
                robotoRegular, robotoBold),
            _row('Contact', patient?['contact'] ?? 'N/A',
                'Address', patient?['address'] ?? 'N/A',
                robotoRegular, robotoBold),
            _row('Collected By', patient?['collected_by'] ?? 'N/A',
                'Requested By', patient?['requested_by'] ?? 'N/A',
                robotoRegular, robotoBold),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _row(
    String label1,
    String value1,
    String label2,
    String value2,
    pw.Font robotoRegular,
    pw.Font robotoBold,
  ) {
    return pw.TableRow(children: [
      _cell(label1, robotoRegular, robotoBold, bold: true),
      _cell(value1, robotoRegular, robotoBold),
      _cell(label2, robotoRegular, robotoBold, bold: true),
      _cell(value2, robotoRegular, robotoBold),
    ]);
  }

  static pw.Widget _cell(
    String text,
    pw.Font robotoRegular,
    pw.Font robotoBold, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? robotoBold : robotoRegular,
          fontSize: 9,
        ),
      ),
    );
  }
}
