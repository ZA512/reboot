import 'package:reboot_domain/reboot_domain.dart';

/// Indicates that local journal entries were not replayed monotonically.
final class LocalJournalOrderException implements Exception {
  /// Creates an ordering error.
  const LocalJournalOrderException({
    required this.previous,
    required this.received,
  });

  /// Last accepted position.
  final LocalJournalPosition previous;

  /// Non-increasing position that was rejected.
  final LocalJournalPosition received;

  @override
  String toString() {
    return 'LocalJournalOrderException: position $received follows $previous';
  }
}

/// Indicates contradictory immutable facts in one journal.
final class ProjectionConflictException implements Exception {
  /// Creates a conflict with a diagnostic [message].
  const ProjectionConflictException(this.message);

  /// Human-readable diagnostic for developers.
  final String message;

  @override
  String toString() => 'ProjectionConflictException: $message';
}

/// Indicates that this projection does not understand an event schema.
final class UnsupportedEventException implements Exception {
  /// Creates an unsupported-event error for [eventType].
  const UnsupportedEventException(this.eventType);

  /// Stable event type rejected by the projection.
  final String eventType;

  @override
  String toString() => 'UnsupportedEventException: $eventType';
}
