import 'package:flutter/material.dart';

import '../../core/extensions/date_time_extensions.dart';

class AppDatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const AppDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
                Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 10),
                // Flexible so a long label ellipsizes in a half-width field
                // instead of overflowing on narrow phones.
                Flexible(
                  child: Text(
                    value == null ? 'Pick a date' : value!.toWeekdayMonthDay,
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
