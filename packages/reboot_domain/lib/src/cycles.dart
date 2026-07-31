import 'local_date.dart';

/// A syntactically valid IANA time-zone identifier retained for audit.
///
/// Existence in the bundled IANA database is checked at the application
/// boundary, where that database is available.
final class IanaTimeZoneId {
  /// Creates a validated identifier such as `Europe/Paris`.
  factory IanaTimeZoneId(String value) {
    final segments = value.split('/');
    final segmentPattern = RegExp(r'^[A-Za-z0-9._+-]+$');
    if (segments.length < 2 ||
        segments.any(
          (segment) =>
              segment.isEmpty ||
              segment == '.' ||
              segment == '..' ||
              !segmentPattern.hasMatch(segment),
        )) {
      throw FormatException('Invalid IANA time-zone identifier: $value');
    }
    return IanaTimeZoneId._(value);
  }

  const IanaTimeZoneId._(this.value);

  /// Canonical identifier persisted with cycles and events.
  final String value;

  @override
  bool operator ==(Object other) {
    return other is IanaTimeZoneId && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Versioned rules used to materialize weekly cycles.
final class CyclePolicy {
  /// Creates an immutable policy snapshot.
  CyclePolicy({
    required this.version,
    required this.effectiveFrom,
    required this.anchorWeekday,
    required this.timeZone,
  }) {
    if (version < 1) {
      throw RangeError.range(version, 1, null, 'version');
    }
  }

  /// Monotonically increasing household policy version.
  final int version;

  /// Civil date from which the policy may take effect.
  final LocalDate effectiveFrom;

  /// Weekday on which normal cycles begin at local midnight.
  final Weekday anchorWeekday;

  /// Household IANA time zone captured for audit.
  final IanaTimeZoneId timeZone;

  /// First normal cycle start permitted by this policy.
  LocalDate get firstNormalCycleStart {
    return effectiveFrom.weekdayOnOrAfter(anchorWeekday);
  }

  @override
  bool operator ==(Object other) {
    return other is CyclePolicy &&
        version == other.version &&
        effectiveFrom == other.effectiveFrom &&
        anchorWeekday == other.anchorWeekday &&
        timeZone == other.timeZone;
  }

  @override
  int get hashCode {
    return Object.hash(version, effectiveFrom, anchorWeekday, timeZone);
  }
}

/// Whether a cycle follows the normal seven-date cadence.
enum WeeklyCycleKind {
  /// Exactly seven consecutive civil dates.
  normal,

  /// Explicit shorter or longer period caused by an anchor change.
  transition,
}

/// User choice for the first cycle when onboarding ends between two anchors.
enum FirstCycleStartChoice {
  /// Wait for the next anchor date; no partial cycle is created.
  nextAnchor,

  /// Reopen the previous full cycle and enter every expense since its start.
  previousAnchorWithExpenseCatchUp,
}

/// A materialized, auditable interval of consecutive civil dates.
///
/// The interval is half-open: [start] is included and [endExclusive] is not.
final class WeeklyCycle {
  const WeeklyCycle._({
    required this.start,
    required this.endExclusive,
    required this.policy,
    required this.kind,
    this.nextPolicy,
  });

  /// Creates a normal seven-date cycle.
  factory WeeklyCycle.normal({
    required LocalDate start,
    required CyclePolicy policy,
  }) {
    if (start.weekday != policy.anchorWeekday) {
      throw ArgumentError.value(
        start,
        'start',
        'A normal cycle must start on the policy anchor weekday.',
      );
    }
    if (start.isBefore(policy.firstNormalCycleStart)) {
      throw ArgumentError.value(
        start,
        'start',
        'A normal cycle cannot start before its policy takes effect.',
      );
    }

    return WeeklyCycle._(
      start: start,
      endExclusive: start.addDays(7),
      policy: policy,
      kind: WeeklyCycleKind.normal,
    );
  }

  /// Creates an exceptional cycle bridging two anchor policies.
  factory WeeklyCycle.transition({
    required LocalDate start,
    required LocalDate endExclusive,
    required CyclePolicy previousPolicy,
    required CyclePolicy nextPolicy,
  }) {
    final dateCount = start.daysUntil(endExclusive);
    if (dateCount <= 0 || dateCount == 7) {
      throw ArgumentError.value(
        dateCount,
        'dateCount',
        'A transition must contain a positive, non-standard date count.',
      );
    }
    if (start.weekday != previousPolicy.anchorWeekday) {
      throw ArgumentError.value(
        start,
        'start',
        'A transition must begin on the previous anchor weekday.',
      );
    }
    if (endExclusive.weekday != nextPolicy.anchorWeekday) {
      throw ArgumentError.value(
        endExclusive,
        'endExclusive',
        'The next normal cycle must begin on the new anchor weekday.',
      );
    }
    if (endExclusive.isBefore(nextPolicy.effectiveFrom)) {
      throw ArgumentError.value(
        endExclusive,
        'endExclusive',
        'The next policy cannot begin before its effective date.',
      );
    }
    if (previousPolicy.version >= nextPolicy.version) {
      throw ArgumentError(
        'The next policy version must exceed the previous version.',
      );
    }

    return WeeklyCycle._(
      start: start,
      endExclusive: endExclusive,
      policy: previousPolicy,
      kind: WeeklyCycleKind.transition,
      nextPolicy: nextPolicy,
    );
  }

  /// First included civil date.
  final LocalDate start;

  /// First civil date not included in this cycle.
  final LocalDate endExclusive;

  /// Policy active at the beginning of this cycle.
  final CyclePolicy policy;

  /// Normal or exceptional transition kind.
  final WeeklyCycleKind kind;

  /// Policy that begins after a transition, otherwise `null`.
  final CyclePolicy? nextPolicy;

  /// Number of civil dates in this cycle.
  int get dateCount => start.daysUntil(endExclusive);

  /// Last included civil date.
  LocalDate get endInclusive => endExclusive.addDays(-1);

  /// Whether normal weekly trend calculations include this cycle by default.
  bool get includedInNormalTrends => kind == WeeklyCycleKind.normal;

  /// Whether [date] belongs to this half-open cycle.
  bool contains(LocalDate date) {
    return !date.isBefore(start) && date.isBefore(endExclusive);
  }
}

/// A policy-change result with a transition and the first new normal cycle.
final class CyclePolicyChange {
  /// Creates a complete, gap-free policy change.
  const CyclePolicyChange({
    required this.transition,
    required this.firstNormalCycle,
  });

  /// Exceptional cycle replacing the old cycle active at the effective date.
  final WeeklyCycle transition;

  /// First seven-date cycle under the new policy.
  final WeeklyCycle firstNormalCycle;
}

/// Pure calendar operations for materializing REBOOT cycles.
abstract final class CycleCalendar {
  /// Resolves the first normal cycle start selected during onboarding.
  static LocalDate firstCycleStart({
    required LocalDate onboardingDate,
    required Weekday anchorWeekday,
    required FirstCycleStartChoice choice,
  }) {
    return switch (choice) {
      FirstCycleStartChoice.nextAnchor => onboardingDate.weekdayOnOrAfter(
        anchorWeekday,
      ),
      FirstCycleStartChoice.previousAnchorWithExpenseCatchUp =>
        onboardingDate.weekdayOnOrBefore(anchorWeekday),
    };
  }

  /// Finds the normal cycle containing [date] under [policy].
  static WeeklyCycle normalCycleContaining({
    required LocalDate date,
    required CyclePolicy policy,
  }) {
    final start = date.weekdayOnOrBefore(policy.anchorWeekday);
    return WeeklyCycle.normal(start: start, policy: policy);
  }

  /// Materializes [count] consecutive normal cycles from [firstStart].
  static List<WeeklyCycle> normalCycles({
    required LocalDate firstStart,
    required int count,
    required CyclePolicy policy,
  }) {
    if (count < 0) {
      throw RangeError.range(count, 0, null, 'count');
    }

    return List<WeeklyCycle>.unmodifiable(
      List<WeeklyCycle>.generate(
        count,
        (index) => WeeklyCycle.normal(
          start: firstStart.addDays(index * 7),
          policy: policy,
        ),
      ),
    );
  }

  /// Plans an anchor-weekday change without rewriting closed cycles.
  static CyclePolicyChange changeAnchor({
    required CyclePolicy previousPolicy,
    required CyclePolicy nextPolicy,
  }) {
    if (previousPolicy.anchorWeekday == nextPolicy.anchorWeekday) {
      throw ArgumentError('An anchor change requires a different weekday.');
    }

    final previousCycle = normalCycleContaining(
      date: nextPolicy.effectiveFrom,
      policy: previousPolicy,
    );
    final nextStart = nextPolicy.firstNormalCycleStart;
    final transition = WeeklyCycle.transition(
      start: previousCycle.start,
      endExclusive: nextStart,
      previousPolicy: previousPolicy,
      nextPolicy: nextPolicy,
    );
    final firstNormalCycle = WeeklyCycle.normal(
      start: nextStart,
      policy: nextPolicy,
    );

    return CyclePolicyChange(
      transition: transition,
      firstNormalCycle: firstNormalCycle,
    );
  }
}
