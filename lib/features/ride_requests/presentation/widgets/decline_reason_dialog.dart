import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Prompts for an optional note explaining why a join request is being
/// declined. Returns the trimmed reason, an empty string if left blank, or
/// `null` if the organizer backed out entirely (decline should not proceed).
Future<String?> showDeclineReasonDialog(BuildContext context, {required String riderName}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Decline $riderName\'s request?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Let them know why (optional) — this is shared with the rider.'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. This ride is at capacity for now',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Decline'),
        ),
      ],
    ),
  );
}
