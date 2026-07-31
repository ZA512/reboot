import 'events.dart';
import 'money.dart';

/// Version 1 snapshot configuring optional aggregate health tracking.
final class HealthTrackingConfiguredPayload implements EventPayload {
  HealthTrackingConfiguredPayload({
    required this.enabled,
    required this.delayWeeks,
    required this.alertThreshold,
  }) {
    if (delayWeeks < 1 || delayWeeks > 52) {
      throw RangeError.range(delayWeeks, 1, 52, 'delayWeeks');
    }
    if (alertThreshold.isNegative || alertThreshold.currency != Currency.eur) {
      throw ArgumentError.value(
        alertThreshold,
        'alertThreshold',
        'A health threshold must be a non-negative EUR value.',
      );
    }
  }

  @override
  String get eventType => 'health-tracking.configured';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.healthTracking;

  final bool enabled;
  final int delayWeeks;
  final Money alertThreshold;
}

/// Version 1 aggregate or individual health expense.
final class HealthExpenseRecordedPayload implements EventPayload {
  HealthExpenseRecordedPayload({required this.amount, required this.label}) {
    _requireHealthEntry(amount, label);
  }

  @override
  String get eventType => 'health.expense-recorded';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.healthTracking;

  final Money amount;
  final String label;
}

/// Version 1 aggregate or individual health reimbursement.
final class HealthReimbursementRecordedPayload implements EventPayload {
  HealthReimbursementRecordedPayload({
    required this.amount,
    required this.label,
  }) {
    _requireHealthEntry(amount, label);
  }

  @override
  String get eventType => 'health.reimbursement-recorded';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.healthTracking;

  final Money amount;
  final String label;
}

/// Version 1 amount that the user has already compensated elsewhere.
final class HealthRegularizationRecordedPayload implements EventPayload {
  HealthRegularizationRecordedPayload({
    required this.amount,
    required this.label,
  }) {
    _requireHealthEntry(amount, label);
  }

  @override
  String get eventType => 'health.regularization-recorded';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.healthTracking;

  final Money amount;
  final String label;
}

/// Version 1 correction neutralizing one erroneous health entry.
final class HealthEntryReversedPayload implements EventPayload {
  const HealthEntryReversedPayload({required this.entryEventId});

  @override
  String get eventType => 'health.entry-reversed';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.healthTracking;

  final EventId entryEventId;
}

void _requireHealthEntry(Money amount, String label) {
  if (!amount.isPositive || amount.currency != Currency.eur) {
    throw ArgumentError.value(
      amount,
      'amount',
      'A health entry must be a positive EUR value.',
    );
  }
  if (label.trim().isEmpty) {
    throw ArgumentError.value(label, 'label', 'A health label is required.');
  }
}
