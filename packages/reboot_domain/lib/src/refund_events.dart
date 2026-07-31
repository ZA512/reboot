import 'events.dart';
import 'local_date.dart';
import 'money.dart';

/// Version 1 payload recording a partial or total product refund.
final class ExpenseRefundedPayload implements EventPayload {
  /// Creates a validated refund tied to its receipt cycle.
  ExpenseRefundedPayload({
    required this.amount,
    required this.receiptCycleStart,
  }) {
    if (!amount.isPositive || amount.currency != Currency.eur) {
      throw ArgumentError.value(
        amount,
        'amount',
        'A refund must be a positive EUR value.',
      );
    }
  }

  @override
  String get eventType => 'expense.refunded';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.expense;

  /// Exact amount received.
  final Money amount;

  /// Materialized cycle containing the receipt date.
  final LocalDate receiptCycleStart;
}

/// Version 1 correction neutralizing an erroneous refund entry.
final class ExpenseRefundReversedPayload implements EventPayload {
  const ExpenseRefundReversedPayload({required this.refundEventId});

  @override
  String get eventType => 'expense.refund-reversed';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.expense;

  /// Immutable refund event being neutralized.
  final EventId refundEventId;
}
