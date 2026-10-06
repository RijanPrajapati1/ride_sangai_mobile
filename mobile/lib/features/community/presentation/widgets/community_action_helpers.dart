import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';

/// Runs a community mutation and shows its error, if any, in a snackbar.
/// Returns true on success.
Future<bool> runCommunityAction(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on AppException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
}

Future<bool> confirmCommunityDelete(BuildContext context, {required String what}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $what?'),
      content: const Text('This can\'t be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
      ],
    ),
  );
  return confirmed ?? false;
}
