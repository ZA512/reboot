import 'events.dart';
import 'money.dart';

/// Whether a reserve maps to a separate bank account or stays internal.
enum ReserveKind {
  /// Money held in a distinct bank account.
  real,

  /// An internal allocation inside the household's main account.
  virtual,
}

/// Version 1 payload establishing one named reserve.
final class ReserveCreatedPayload implements EventPayload {
  /// Creates a validated EUR reserve.
  ReserveCreatedPayload({
    required this.name,
    required this.kind,
    required this.openingBalance,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'A reserve name is required.');
    }
    if (openingBalance.isNegative || openingBalance.currency != Currency.eur) {
      throw ArgumentError.value(
        openingBalance,
        'openingBalance',
        'A reserve opening balance must be a non-negative EUR value.',
      );
    }
  }

  @override
  String get eventType => 'reserve.created';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.reserve;

  /// User-visible reserve name.
  final String name;

  /// Real account or virtual allocation.
  final ReserveKind kind;

  /// Declared amount available when tracking begins.
  final Money openingBalance;
}

/// Version 1 payload recording money assigned to a reserve.
final class ReserveFundsAddedPayload implements EventPayload {
  /// Creates one transfer-like reserve credit.
  ReserveFundsAddedPayload({required this.amount, required this.label}) {
    _requirePositiveAmount(amount);
    _requireLabel(label);
  }

  @override
  String get eventType => 'reserve.funds-added';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.reserve;

  /// Exact amount assigned to the reserve.
  final Money amount;

  /// User-visible explanation, such as a saved surplus.
  final String label;
}

/// Version 1 payload for a real expense financed from a reserve.
final class ReserveExpenseRecordedPayload implements EventPayload {
  /// Creates one reserve-funded expense.
  ReserveExpenseRecordedPayload({required this.amount, required this.label}) {
    _requirePositiveAmount(amount);
    _requireLabel(label);
  }

  @override
  String get eventType => 'reserve.expense-recorded';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.reserve;

  /// Exact amount paid from the selected reserve.
  final Money amount;

  /// User-visible purchase description.
  final String label;
}

/// Version 1 correction that reverses one erroneous reserve movement.
final class ReserveMovementReversedPayload implements EventPayload {
  /// Creates a correction referencing the immutable original event.
  const ReserveMovementReversedPayload({required this.movementEventId});

  @override
  String get eventType => 'reserve.movement-reversed';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.reserve;

  /// Funding or expense event being neutralized.
  final EventId movementEventId;
}

void _requirePositiveAmount(Money amount) {
  if (!amount.isPositive || amount.currency != Currency.eur) {
    throw ArgumentError.value(
      amount,
      'amount',
      'A reserve movement must be a positive EUR value.',
    );
  }
}

void _requireLabel(String label) {
  if (label.trim().isEmpty) {
    throw ArgumentError.value(label, 'label', 'A movement label is required.');
  }
}
