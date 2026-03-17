import 'package:pdf/widgets.dart' as pw;

class LabResultsTable {
  static pw.Widget build(List<Map<String, dynamic>> results) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
      
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header row
            pw.TableRow(children: [
              _cell('Test Name', bold: true),
              _cell('Result', bold: true),
              _cell('Flag', bold: true),
              _cell('Unit Measure', bold: true),
              _cell('Normal Range', bold: true),
            ]),

            // Dynamic rows
            ...results.map((test) => pw.TableRow(children: [
                  _cell(test['name'] ?? ''),
                  _cell(test['result']?.toString() ?? ''),
                  _cell(test['flag'] ?? ''),
                  _cell(test['unit'] ?? ''),
                  _cell(test['range'] ?? ''),
                ])),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
