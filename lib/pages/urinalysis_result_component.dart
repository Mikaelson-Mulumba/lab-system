import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class UrinalysisResultsComponent extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> results)? onResultsChanged;

  const UrinalysisResultsComponent({super.key, this.onResultsChanged});

  @override
  State<UrinalysisResultsComponent> createState() =>
      _UrinalysisResultsComponentState();
}

class _UrinalysisResultsComponentState extends State<UrinalysisResultsComponent> {
  List<Map<String, dynamic>> urinalysisParams = [];
  final List<UrinalysisGroup> groups = [];

  @override
  void initState() {
    super.initState();
    _fetchUrinalysisParams();
  }

  Future<void> _fetchUrinalysisParams() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('urinalysis');
    if (!mounted) return;
    setState(() {
      urinalysisParams = data.cast<Map<String, dynamic>>();
    });
  }

  void _notifyParent() {
    final allResults = groups.expand((g) => g.collectResults()).toList();
    widget.onResultsChanged?.call(allResults);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: groups
              .map((g) => g.build(context, urinalysisParams, _notifyParent))
              .toList(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            setState(() {
              groups.add(UrinalysisGroup());
            });
            _notifyParent();
          },
          child: const Text('➕ Add Category Group'),
        ),
      ],
    );
  }
}

class UrinalysisGroup {
  String? category;
  final List<UrinalysisRow> rows = [];

  Widget build(BuildContext context,
      List<Map<String, dynamic>> urinalysisParams, VoidCallback notifyParent) {
    final categories =
        urinalysisParams.map((p) => p['category'] as String).toSet().toList();
    final filteredParams = category == null
        ? <Map<String, dynamic>>[]
        : urinalysisParams
            .where((p) => p['category'] == category)
            .toList()
            .cast<Map<String, dynamic>>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              initialValue: category,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                category = val;
                rows.clear(); // reset rows when category changes
                notifyParent();
              },
            ),
            const SizedBox(height: 12),

            // ✅ Table with header row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(label: Text('Parameter')),
                  DataColumn(label: Text('Reference Range')),
                  DataColumn(label: Text('Result')),
                  DataColumn(label: Text('Unit')),
                ],
                rows: rows
                    .map((r) => r.buildRow(context, filteredParams, notifyParent))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                rows.add(UrinalysisRow());
                notifyParent();
              },
              child: const Text('➕ Add Parameter'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> collectResults() {
    return rows.map((r) => r.collectResult(category)).toList();
  }
}
class UrinalysisRow {
  String? paramId;
  String? name;
  String? referenceRange;
  String? unit;
  String result = '';

  Map<String, dynamic> collectResult(String? category) {
    return {
      'category': category ?? '',
      'name': name ?? '',
      'reference_range': referenceRange ?? '',
      'unit': unit ?? '',
      'result': result,
    };
  }

  DataRow buildRow(BuildContext context,
      List<Map<String, dynamic>> filteredParams, VoidCallback notifyParent) {
    final selectedParam = paramId == null
        ? <String, dynamic>{}
        : filteredParams.firstWhere(
            (p) => p['id'].toString() == paramId,
            orElse: () => <String, dynamic>{},
          );

    if (selectedParam.isNotEmpty) {
      name = selectedParam['name'] as String?;
      referenceRange = selectedParam['reference_range'] as String?;
      unit = selectedParam['unit'] as String?;
    }

    return DataRow(
      cells: [
        DataCell(
          DropdownButton<String>(
            isExpanded: true,
            value: paramId,
            hint: const Text('Select Parameter'),
            items: filteredParams
                .map((p) => DropdownMenuItem(
                      value: p['id'].toString(),
                      child: Text(p['name']),
                    ))
                .toList(),
            onChanged: (val) {
              paramId = val;
              result = '';
              notifyParent();
            },
          ),
        ),
        DataCell(Text(referenceRange ?? '')),
        DataCell(
          TextFormField(
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter result',
            ),
            onChanged: (val) {
              result = val;
              notifyParent();
            },
          ),
        ),
        DataCell(Text(unit ?? '')),
      ],
    );
  }
}
