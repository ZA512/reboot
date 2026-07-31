import 'local_date.dart';
import 'money.dart';

/// User-selected purpose for the capacity kept outside weekly spending.
enum TrajectoryStrategy {
  /// No hidden saving target beyond explicitly entered amounts.
  balance,

  /// Builds a user-selected annual reserve cushion.
  cushion,

  /// Recovers an overdraft and optional positive cushion by a target date.
  overdraftExit,
}

/// A time-bound recovery goal whose progress must be confirmed by the user.
final class OverdraftExitGoal {
  /// Creates an exact EUR target.
  OverdraftExitGoal({
    required this.currentOverdraftDepth,
    required this.targetCushion,
    required this.targetDate,
  }) {
    _requireNonNegativeEur(currentOverdraftDepth, 'currentOverdraftDepth');
    _requireNonNegativeEur(targetCushion, 'targetCushion');
    if (totalToRecover.isZero) {
      throw ArgumentError(
        'An overdraft exit goal must recover a positive amount.',
      );
    }
  }

  /// Positive depth below zero at confirmation time.
  final Money currentOverdraftDepth;

  /// Positive balance the user wants after clearing the overdraft.
  final Money targetCushion;

  /// Civil date on which REBOOT asks the user to confirm the result.
  final LocalDate targetDate;

  /// Exact improvement required between the current and target balances.
  Money get totalToRecover => currentOverdraftDepth + targetCushion;
}

void _requireNonNegativeEur(Money amount, String name) {
  if (amount.isNegative || amount.currency != Currency.eur) {
    throw ArgumentError.value(
      amount,
      name,
      'A trajectory amount must be a non-negative EUR value.',
    );
  }
}
