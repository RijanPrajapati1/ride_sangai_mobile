import '../../../../core/errors/app_exception.dart';

/// Text to show for a failure: the API's own message for an [AppException],
/// a generic one for anything unexpected.
String errorMessage(Object error) =>
    error is AppException ? error.message : 'Something went wrong. Please try again.';
