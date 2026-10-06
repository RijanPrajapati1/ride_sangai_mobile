import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';

/// Runs [action] and, if it fails, shows the error in a SnackBar. API errors
/// carry a message written for users (for example "This ride is full."), so
/// it's shown as-is.
Future<void> runOrShowError(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    final message = error is AppException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
