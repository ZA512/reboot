import 'local_date.dart';
import 'money.dart';

/// Whether money enters or leaves the household trajectory.
enum CashFlowDirection {
  /// Salary, benefit, pension, or another recurring receipt.
  income,

  /// Fixed charge or smoothed unavoidable expense.
  outflow,
}

/// Whether the expected amount is known or estimated from history.
enum AmountBehavior {
  /// The amount expected at each occurrence is known.
  fixed,

  /// The amount is an estimate that must be confirmed periodically.
  variable,
}

/// How a variable amount is derived from its historical average.
enum VariableEstimateStrategy {
  /// Income uses 90%; outflow uses 110%.
  prudent,

  /// Uses 100% of the historical average.
  balanced,

  /// Uses an amount explicitly chosen by the user.
  custom,
}

/// Common recurrence cadences offered by REBOOT.
enum RecurrenceFrequency {
  /// Every seven civil dates.
  weekly,

  /// Every 28 civil dates.
  everyFourWeeks,

  /// The same intended day in every calendar month.
  monthly,

  /// The same intended day every three calendar months.
  quarterly,

  /// The same intended day every six calendar months.
  semiAnnual,

  /// The same intended day every twelve calendar months.
  annual,
}

/// Dates on which a cash flow is expected.
sealed class OccurrenceSchedule {
  const OccurrenceSchedule();

  /// Returns occurrences in `[startInclusive, endExclusive)`.
  List<LocalDate> occurrencesBetween({
    required LocalDate startInclusive,
    required LocalDate endExclusive,
  });
}

/// A recurring schedule anchored to its first expected occurrence.
///
/// Month-based schedules preserve the intended original day. If it does not
/// exist in a target month, that occurrence is clamped to the month's final
/// date; a January 31 schedule therefore yields February 28/29 then March 31.
final class RecurringSchedule extends OccurrenceSchedule {
  /// Creates a recurring schedule with an optional inclusive final occurrence.
  RecurringSchedule({
    required this.firstOccurrence,
    required this.frequency,
    this.lastOccurrence,
  }) {
    if (lastOccurrence case final last? when last.isBefore(firstOccurrence)) {
      throw ArgumentError.value(
        last,
        'lastOccurrence',
        'The last occurrence cannot precede the first.',
      );
    }
  }

  /// First date on which the flow may occur.
  final LocalDate firstOccurrence;

  /// Recurrence cadence.
  final RecurrenceFrequency frequency;

  /// Optional inclusive final occurrence date.
  final LocalDate? lastOccurrence;

  @override
  List<LocalDate> occurrencesBetween({
    required LocalDate startInclusive,
    required LocalDate endExclusive,
  }) {
    _validateInterval(startInclusive, endExclusive);
    return List<LocalDate>.unmodifiable(switch (frequency) {
      RecurrenceFrequency.weekly => _dayOccurrences(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        intervalDays: 7,
      ),
      RecurrenceFrequency.everyFourWeeks => _dayOccurrences(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        intervalDays: 28,
      ),
      RecurrenceFrequency.monthly => _monthOccurrences(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        intervalMonths: 1,
      ),
      RecurrenceFrequency.quarterly => _monthOccurrences(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        intervalMonths: 3,
      ),
      RecurrenceFrequency.semiAnnual => _monthOccurrences(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        intervalMonths: 6,
      ),
      RecurrenceFrequency.annual => _monthOccurrences(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        intervalMonths: 12,
      ),
    });
  }

  List<LocalDate> _dayOccurrences({
    required LocalDate startInclusive,
    required LocalDate endExclusive,
    required int intervalDays,
  }) {
    var index = 0;
    if (firstOccurrence.isBefore(startInclusive)) {
      index = firstOccurrence.daysUntil(startInclusive) ~/ intervalDays;
      if (firstOccurrence
          .addDays(index * intervalDays)
          .isBefore(startInclusive)) {
        index += 1;
      }
    }

    final result = <LocalDate>[];
    while (true) {
      final occurrence = firstOccurrence.addDays(index * intervalDays);
      if (!occurrence.isBefore(endExclusive) || _isAfterLast(occurrence)) {
        break;
      }
      if (!occurrence.isBefore(startInclusive)) {
        result.add(occurrence);
      }
      index += 1;
    }
    return result;
  }

  List<LocalDate> _monthOccurrences({
    required LocalDate startInclusive,
    required LocalDate endExclusive,
    required int intervalMonths,
  }) {
    var index = 0;
    if (firstOccurrence.isBefore(startInclusive)) {
      final elapsedMonths =
          (startInclusive.year - firstOccurrence.year) * 12 +
          startInclusive.month -
          firstOccurrence.month;
      index = elapsedMonths ~/ intervalMonths;
      if (_atMonthOffset(index * intervalMonths).isBefore(startInclusive)) {
        index += 1;
      }
    }

    final result = <LocalDate>[];
    while (true) {
      final occurrence = _atMonthOffset(index * intervalMonths);
      if (!occurrence.isBefore(endExclusive) || _isAfterLast(occurrence)) {
        break;
      }
      if (!occurrence.isBefore(startInclusive)) {
        result.add(occurrence);
      }
      index += 1;
    }
    return result;
  }

  LocalDate _atMonthOffset(int monthOffset) {
    final zeroBasedMonth =
        firstOccurrence.year * 12 + firstOccurrence.month - 1 + monthOffset;
    final year = zeroBasedMonth ~/ 12;
    final month = zeroBasedMonth % 12 + 1;
    if (year < 1 || year > 9999) {
      throw RangeError('Recurrence exceeded the supported year range.');
    }
    final finalDay = DateTime.utc(year, month + 1, 0).day;
    final day = firstOccurrence.day > finalDay ? finalDay : firstOccurrence.day;
    return LocalDate(year, month, day);
  }

  bool _isAfterLast(LocalDate occurrence) {
    final last = lastOccurrence;
    return last != null && occurrence.isAfter(last);
  }
}

/// A finite set of user-supplied expected dates.
final class CustomDateSchedule extends OccurrenceSchedule {
  /// Creates a normalized, chronological schedule without duplicate dates.
  CustomDateSchedule(Iterable<LocalDate> dates)
    : dates = _normalizedDates(dates);

  /// Expected dates in chronological order.
  final List<LocalDate> dates;

  @override
  List<LocalDate> occurrencesBetween({
    required LocalDate startInclusive,
    required LocalDate endExclusive,
  }) {
    _validateInterval(startInclusive, endExclusive);
    return List<LocalDate>.unmodifiable(
      dates.where(
        (date) => !date.isBefore(startInclusive) && date.isBefore(endExclusive),
      ),
    );
  }

  static List<LocalDate> _normalizedDates(Iterable<LocalDate> source) {
    final normalized = source.toSet().toList()..sort();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        source,
        'dates',
        'At least one date is required.',
      );
    }
    return List<LocalDate>.unmodifiable(normalized);
  }
}

/// One income or outflow definition used to forecast the household trajectory.
final class CashFlowDefinition {
  CashFlowDefinition._({
    required this.title,
    required this.direction,
    required this.behavior,
    required this.schedule,
    required this.referenceAmountPerOccurrence,
    required this.variableStrategy,
    required this.customAmountPerOccurrence,
    this.lastConfirmedOn,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'A title is required.');
    }
    _requireNonNegative(
      referenceAmountPerOccurrence,
      'referenceAmountPerOccurrence',
    );
    final custom = customAmountPerOccurrence;
    if (custom != null) {
      _requireNonNegative(custom, 'customAmountPerOccurrence');
      if (custom.currency != referenceAmountPerOccurrence.currency) {
        throw CurrencyMismatchException(
          referenceAmountPerOccurrence.currency,
          custom.currency,
        );
      }
    }
  }

  /// Creates a flow whose amount is known at each occurrence.
  factory CashFlowDefinition.fixed({
    required String title,
    required CashFlowDirection direction,
    required OccurrenceSchedule schedule,
    required Money amountPerOccurrence,
    LocalDate? lastConfirmedOn,
  }) {
    return CashFlowDefinition._(
      title: title.trim(),
      direction: direction,
      behavior: AmountBehavior.fixed,
      schedule: schedule,
      referenceAmountPerOccurrence: amountPerOccurrence,
      variableStrategy: null,
      customAmountPerOccurrence: null,
      lastConfirmedOn: lastConfirmedOn,
    );
  }

  /// Creates an estimated flow from history or a user-selected amount.
  factory CashFlowDefinition.variable({
    required String title,
    required CashFlowDirection direction,
    required OccurrenceSchedule schedule,
    required Money historicalAveragePerOccurrence,
    required VariableEstimateStrategy strategy,
    Money? customAmountPerOccurrence,
    LocalDate? lastConfirmedOn,
  }) {
    if (strategy == VariableEstimateStrategy.custom &&
        customAmountPerOccurrence == null) {
      throw ArgumentError(
        'A custom variable strategy requires a custom amount.',
      );
    }
    if (strategy != VariableEstimateStrategy.custom &&
        customAmountPerOccurrence != null) {
      throw ArgumentError(
        'A custom amount is only valid with the custom strategy.',
      );
    }
    return CashFlowDefinition._(
      title: title.trim(),
      direction: direction,
      behavior: AmountBehavior.variable,
      schedule: schedule,
      referenceAmountPerOccurrence: historicalAveragePerOccurrence,
      variableStrategy: strategy,
      customAmountPerOccurrence: customAmountPerOccurrence,
      lastConfirmedOn: lastConfirmedOn,
    );
  }

  /// User-facing label such as "Salaire 1" or "Électricité".
  final String title;

  /// Income or outflow.
  final CashFlowDirection direction;

  /// Fixed or variable amount selector.
  final AmountBehavior behavior;

  /// Expected occurrence dates.
  final OccurrenceSchedule schedule;

  /// Known amount or historical average for one occurrence.
  final Money referenceAmountPerOccurrence;

  /// Estimation rule for a variable flow, otherwise `null`.
  final VariableEstimateStrategy? variableStrategy;

  /// User-selected amount for one occurrence, when applicable.
  final Money? customAmountPerOccurrence;

  /// Date on which the estimate was last confirmed by the user.
  final LocalDate? lastConfirmedOn;

  static void _requireNonNegative(Money amount, String name) {
    if (amount.isNegative) {
      throw ArgumentError.value(
        amount,
        name,
        'Cash-flow amounts are unsigned.',
      );
    }
  }
}

/// The remaining part of an already received bonus assigned to daily life.
///
/// A future expected bonus is deliberately absent from this model. At
/// [nextPaymentDate], the user must confirm what was actually received and
/// create a new pool for the part they choose to inject into daily life.
final class ReceivedBonusPool {
  /// Creates an available pool with its mandatory renewal date.
  ReceivedBonusPool({
    required String title,
    required this.remainingForDailyLife,
    required this.nextPaymentDate,
  }) : title = title.trim() {
    if (this.title.isEmpty) {
      throw ArgumentError.value(title, 'title', 'A title is required.');
    }
    if (remainingForDailyLife.isNegative) {
      throw ArgumentError.value(
        remainingForDailyLife,
        'remainingForDailyLife',
        'A received bonus pool cannot be negative.',
      );
    }
  }

  /// User-facing label.
  final String title;

  /// Money that still exists and was explicitly assigned to daily life.
  final Money remainingForDailyLife;

  /// Date on which a newly received amount must be confirmed.
  final LocalDate nextPaymentDate;
}

void _validateInterval(LocalDate startInclusive, LocalDate endExclusive) {
  if (!startInclusive.isBefore(endExclusive)) {
    throw ArgumentError('The occurrence interval must be non-empty.');
  }
}
