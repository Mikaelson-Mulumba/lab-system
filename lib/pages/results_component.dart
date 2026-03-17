import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class ResultsComponent extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> results)? onResultsChanged;

  const ResultsComponent({super.key, this.onResultsChanged});

  @override
  State<ResultsComponent> createState() => _ResultsComponentState();
}

class _ResultsComponentState extends State<ResultsComponent> {
  List<Map<String, dynamic>> testTypes = [];
  final List<TestTypeGroup> groups = [];

  @override
  void initState() {
    super.initState();
    _fetchTestTypes();
  }

  Future<void> _fetchTestTypes() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('test_types');
    if (!mounted) return;
    setState(() {
      testTypes = data.cast<Map<String, dynamic>>();
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
          children: groups.map((g) => g.build(context, _notifyParent)).toList(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            setState(() {
              groups.add(TestTypeGroup(testTypes));
            });
            _notifyParent();
          },
          child: const Text('➕ Add Test Type'),
        ),
      ],
    );
  }
}

class TestTypeGroup {
  String? selectedType;
  final List<Map<String, dynamic>> testTypes;
  final List<TestRow> tests = [];

  TestTypeGroup(this.testTypes);

  Widget build(BuildContext context, VoidCallback notifyParent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Test Type'),
              items: testTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t['id'].toString(),
                      child: Text(t['test_type']),
                    ),
                  )
                  .toList(),
              initialValue: selectedType,
              onChanged: (val) {
                selectedType = val;
                tests.clear();
                notifyParent();
              },
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(label: Text('Test Name')),
                  DataColumn(label: Text('Reference Range')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Result')),
                  DataColumn(label: Text('Flag')),
                ],
                rows: tests
                    .map((row) => row.buildRow(context, selectedType, notifyParent))
                    .toList(),
              ),
            ),

            if (tests.any((t) => t.comment.isNotEmpty))
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tests
                      .where((t) => t.comment.isNotEmpty)
                      .map((t) => Text(
                            'Comment: ${t.comment}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                tests.add(TestRow());
                notifyParent();
              },
              child: const Text('➕ Add Test'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> collectResults() {
    final typeName = testTypes.firstWhere(
      (t) => t['id'].toString() == selectedType,
      orElse: () => {'test_type': 'Unknown'},
    )['test_type'];

    return tests
        .map(
          (row) => {
            'test_type': typeName,
            'name': row.selectedTestName ?? '',
            'reference_range': row.referenceRange ?? '',
            'unit': row.unit ?? '',
            'result': row.result,
            'flag': row.flag,
            'comment': row.comment,
          },
        )
        .toList();
  }
}

class TestRow {
  String? testId;
  String? selectedTestName;
  String? referenceRange;
  String? unit;
  String result = '';
  String? flag; // allow null
  String comment = '';
  List<String> availableFlags = [];
  Map<String, String> flagComments = {};

  // Controller for reference range
  final TextEditingController referenceController = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchTests(String? typeId) async {
    if (typeId == null) return [];
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'tests',
      where: 'test_type_id = ?',
      whereArgs: [typeId],
    );
    return rows.cast<Map<String, dynamic>>();
  }

  DataRow buildRow(BuildContext context, String? typeId, VoidCallback notifyParent) {
    return DataRow(
      cells: [
        // ✅ Test Name dropdown
        DataCell(
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTests(typeId),
            builder: (context, snapshot) {
              final testsList = snapshot.data ?? [];
              return DropdownButton<String>(
                isExpanded: true,
                value: (testId != null &&
                        testsList.any((t) => t['id'].toString() == testId))
                    ? testId
                    : null,
                hint: const Text('Select Test'),
                items: testsList
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id'].toString(),
                        child: Text(t['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  testId = val;
                  final selectedTest = testsList.firstWhere(
                    (t) => t['id'].toString() == val,
                    orElse: () => {},
                  );
                  selectedTestName = selectedTest['name'];
                  referenceRange = selectedTest['reference_range'];
                  unit = selectedTest['unit'];

                  // update controller text so it displays DB value
                  referenceController.text = referenceRange ?? '';

                  // collect flags + comments
                  final relatedTests = testsList.where((t) => t['name'] == selectedTestName);
                  availableFlags = relatedTests
                      .map((t) => t['result_category']?.toString() ?? '')
                      .where((f) => f.isNotEmpty)
                      .toSet()
                      .toList();

                  flagComments = {
                    for (var t in relatedTests)
                      if ((t['result_category'] ?? '').toString().isNotEmpty)
                        t['result_category'].toString(): t['comment']?.toString() ?? ''
                  };

                  // default flag + comment
                  if (availableFlags.isNotEmpty) {
                    flag = availableFlags.first;
                    comment = flagComments[flag] ?? '';
                  } else {
                    flag = null;
                    comment = '';
                  }

                  notifyParent();
                },
              );
            },
          ),
        ),

        // ✅ Editable Reference Range (shows DB value, editable temporarily)
        DataCell(
          TextFormField(
            controller: referenceController,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            onChanged: (val) {
              referenceRange = val; // temporary edit
              notifyParent();
            },
          ),
        ),

        // ✅ Unit (read-only)
        DataCell(Text(unit ?? '')),

        // ✅ Editable Result
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

        // ✅ Editable Flag dropdown (empty clears comment)
        DataCell(
          DropdownButton<String>(
            value: (flag != null && availableFlags.contains(flag)) ? flag : null,
            hint: const Text('Select Flag'),
            items: availableFlags
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (val) {
              flag = val;
              if (flag == null || flag!.isEmpty) {
                comment = ''; // clear comment if flag is empty
              } else {
                comment = flagComments[flag] ?? '';
              }
              notifyParent();
            },
          ),
        ),
      ],
    );
  }
}
