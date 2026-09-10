import 'package:flutter/material.dart';

import '../../app/theme/app_dimensions.dart';

/// Freeform tag/chip entry used by both the create-ride requirements list
/// and the edit-profile cycling interests list.
class ChipInputField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  const ChipInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty || widget.values.contains(value)) return;
    widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((r) => r != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(hintText: widget.hint),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: _add, icon: const Icon(Icons.add)),
          ],
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spaceSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in widget.values) Chip(label: Text(item), onDeleted: () => _remove(item)),
            ],
          ),
        ],
      ],
    );
  }
}
