/// Small helpers for reading API JSON in DTOs.
library;

/// Enum values in the API match the Dart enum names (`hillClimb`,
/// `requestApproved`). Unknown values (a newer server) fall back to
/// [fallback] instead of crashing the app.
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

/// Timestamps are ISO-8601 strings in UTC; shown in the device's local time.
DateTime parseDate(Object? value) => DateTime.parse(value as String).toLocal();

DateTime? parseDateOrNull(Object? value) => value == null ? null : parseDate(value);

/// Sends a date to the API as an ISO-8601 UTC string.
String toApiDate(DateTime date) => date.toUtc().toIso8601String();

/// JSON numbers may arrive as int or double.
double toDouble(Object? value) => (value as num).toDouble();

double? toDoubleOrNull(Object? value) => value == null ? null : (value as num).toDouble();

List<String> stringList(Object? value) => value == null ? const [] : List<String>.from(value as List);
