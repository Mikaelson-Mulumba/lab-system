import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class SpecimensComponent extends StatefulWidget {
  final void Function(List<String> specimens)? onChanged;

  const SpecimensComponent({super.key, this.onChanged});

  @override
  State<SpecimensComponent> createState() => _SpecimensComponentState();
}

class _SpecimensComponentState extends State<SpecimensComponent> {
  List<Map<String, dynamic>> specimens = [];
  List<int> selectedSpecimenIds = [];

  @override
  void initState() {
    super.initState();
    _fetchSpecimens();
  }

  Future<void> _fetchSpecimens() async {
    final db = await DatabaseHelper.instance.database;
    specimens = await db.query('specimens');
    if (!mounted) return;
    setState(() {});
  }

  void _toggleSpecimen(int id, bool selected) {
    setState(() {
      selected ? selectedSpecimenIds.add(id) : selectedSpecimenIds.remove(id);
    });

    // Notify parent with specimen names
    final selectedNames = specimens
        .where((s) => selectedSpecimenIds.contains(s['id']))
        .map((s) => s['name'].toString())
        .toList();

    widget.onChanged?.call(selectedNames);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Specimens',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: specimens.map((s) {
            final id = s['id'] as int;
            final selected = selectedSpecimenIds.contains(id);
            return FilterChip(
              label: Text(s['name']),
              selected: selected,
              onSelected: (checked) => _toggleSpecimen(id, checked),
            );
          }).toList(),
        ),
      ],
    );
  }
}
