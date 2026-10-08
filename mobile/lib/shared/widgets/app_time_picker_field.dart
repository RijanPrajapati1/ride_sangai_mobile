import 'package:flutter/material.dart';

class AppTimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;

  const AppTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 10),
                // Flexible so a long label ellipsizes in a half-width field
                // instead of overflowing on narrow phones.
                Flexible(
                  child: Text(
                    value == null ? 'Select a time' : value!.format(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: value == null ? Theme.of(context).inputDecorationTheme.hintStyle : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
