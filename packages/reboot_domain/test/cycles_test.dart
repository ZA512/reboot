import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

void main() {
  setUpAll(timezone_data.initializeTimeZones);

  group('IanaTimeZoneId', () {
    test('accepts auditable IANA identifiers', () {
      expect(IanaTimeZoneId('Europe/Paris').value, 'Europe/Paris');
      expect(IanaTimeZoneId('Etc/UTC').value, 'Etc/UTC');
      expect(
        IanaTimeZoneId('America/Argentina/Buenos_Aires').value,
        'America/Argentina/Buenos_Aires',
      );
    });

    test('rejects malformed identifiers', () {
      expect(() => IanaTimeZoneId('Europe Paris'), throwsFormatException);
      expect(() => IanaTimeZoneId('Paris'), throwsFormatException);
      expect(() => IanaTimeZoneId('../Paris'), throwsFormatException);
    });
  });

  group('normal weekly cycles', () {
    test('starts onboarding at the next or previous complete anchor', () {
      final onboardingDate = LocalDate(2026, 4, 1);

      expect(
        CycleCalendar.firstCycleStart(
          onboardingDate: onboardingDate,
          anchorWeekday: Weekday.saturday,
          choice: FirstCycleStartChoice.nextAnchor,
        ),
        LocalDate(2026, 4, 4),
      );
      expect(
        CycleCalendar.firstCycleStart(
          onboardingDate: onboardingDate,
          anchorWeekday: Weekday.saturday,
          choice: FirstCycleStartChoice.previousAnchorWithExpenseCatchUp,
        ),
        LocalDate(2026, 3, 28),
      );
    });

    test(
      'uses today for either onboarding choice when today is the anchor',
      () {
        final saturday = LocalDate(2026, 4, 4);

        for (final choice in FirstCycleStartChoice.values) {
          expect(
            CycleCalendar.firstCycleStart(
              onboardingDate: saturday,
              anchorWeekday: Weekday.saturday,
              choice: choice,
            ),
            saturday,
          );
        }
      },
    );

    test('contains exactly seven consecutive civil dates', () {
      final policy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 3, 28),
        anchor: Weekday.saturday,
      );
      final cycle = WeeklyCycle.normal(
        start: LocalDate(2026, 3, 28),
        policy: policy,
      );

      expect(cycle.dateCount, 7);
      expect(cycle.endInclusive, LocalDate(2026, 4, 3));
      expect(cycle.endExclusive, LocalDate(2026, 4, 4));
      expect(cycle.includedInNormalTrends, isTrue);
      expect(cycle.contains(LocalDate(2026, 3, 28)), isTrue);
      expect(cycle.contains(LocalDate(2026, 4, 3)), isTrue);
      expect(cycle.contains(LocalDate(2026, 4, 4)), isFalse);
    });

    test('crosses spring DST in 167 hours but still has seven dates', () {
      final paris = timezone.getLocation('Europe/Paris');
      final policy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 3, 28),
        anchor: Weekday.saturday,
      );
      final cycle = WeeklyCycle.normal(
        start: LocalDate(2026, 3, 28),
        policy: policy,
      );

      final startInstant = _midnight(cycle.start, paris);
      final endInstant = _midnight(cycle.endExclusive, paris);

      expect(endInstant.difference(startInstant).inHours, 167);
      expect(cycle.dateCount, 7);
    });

    test('crosses autumn DST in 169 hours but still has seven dates', () {
      final paris = timezone.getLocation('Europe/Paris');
      final policy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 10, 24),
        anchor: Weekday.saturday,
      );
      final cycle = WeeklyCycle.normal(
        start: LocalDate(2026, 10, 24),
        policy: policy,
      );

      final startInstant = _midnight(cycle.start, paris);
      final endInstant = _midnight(cycle.endExclusive, paris);

      expect(endInstant.difference(startInstant).inHours, 169);
      expect(cycle.dateCount, 7);
    });

    test('assigns purchases immediately around local midnight', () {
      final paris = timezone.getLocation('Europe/Paris');
      final policy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 3, 21),
        anchor: Weekday.saturday,
      );
      final currentCycle = WeeklyCycle.normal(
        start: LocalDate(2026, 3, 28),
        policy: policy,
      );
      final beforeMidnight = timezone.TZDateTime(
        paris,
        2026,
        3,
        27,
        23,
        59,
        59,
      );
      final atMidnight = timezone.TZDateTime(paris, 2026, 3, 28);

      expect(
        currentCycle.contains(LocalDate.fromDateTime(beforeMidnight)),
        isFalse,
      );
      expect(currentCycle.contains(LocalDate.fromDateTime(atMidnight)), isTrue);
    });

    test('materializes a gap-free 52-cycle horizon', () {
      final policy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 1, 3),
        anchor: Weekday.saturday,
      );
      final cycles = CycleCalendar.normalCycles(
        firstStart: LocalDate(2026, 1, 3),
        count: 52,
        policy: policy,
      );

      expect(cycles, hasLength(52));
      for (var index = 1; index < cycles.length; index++) {
        expect(cycles[index - 1].endExclusive, cycles[index].start);
      }
      expect(cycles.last.endExclusive, LocalDate(2027, 1, 2));
    });

    test('rejects a normal cycle on the wrong anchor or before policy', () {
      final policy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 4, 1),
        anchor: Weekday.saturday,
      );

      expect(
        () => WeeklyCycle.normal(start: LocalDate(2026, 4, 1), policy: policy),
        throwsArgumentError,
      );
      expect(
        () => WeeklyCycle.normal(start: LocalDate(2026, 3, 28), policy: policy),
        throwsArgumentError,
      );
    });
  });

  group('anchor policy changes', () {
    test('creates a five-date short transition', () {
      final change = CycleCalendar.changeAnchor(
        previousPolicy: _policy(
          version: 1,
          effectiveFrom: LocalDate(2026, 3, 28),
          anchor: Weekday.saturday,
        ),
        nextPolicy: _policy(
          version: 2,
          effectiveFrom: LocalDate(2026, 4, 1),
          anchor: Weekday.thursday,
        ),
      );

      expect(change.transition.start, LocalDate(2026, 3, 28));
      expect(change.transition.endExclusive, LocalDate(2026, 4, 2));
      expect(change.transition.dateCount, 5);
      expect(change.transition.kind, WeeklyCycleKind.transition);
      expect(change.transition.includedInNormalTrends, isFalse);
      expect(change.firstNormalCycle.start, change.transition.endExclusive);
      expect(change.firstNormalCycle.dateCount, 7);
    });

    test('creates a nine-date long transition', () {
      final change = CycleCalendar.changeAnchor(
        previousPolicy: _policy(
          version: 1,
          effectiveFrom: LocalDate(2026, 3, 28),
          anchor: Weekday.saturday,
        ),
        nextPolicy: _policy(
          version: 2,
          effectiveFrom: LocalDate(2026, 4, 1),
          anchor: Weekday.monday,
        ),
      );

      expect(change.transition.start, LocalDate(2026, 3, 28));
      expect(change.transition.endExclusive, LocalDate(2026, 4, 6));
      expect(change.transition.dateCount, 9);
      expect(change.firstNormalCycle.start, LocalDate(2026, 4, 6));
    });

    test('leaves no gap or overlap around a transition', () {
      final previousPolicy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 3, 21),
        anchor: Weekday.saturday,
      );
      final change = CycleCalendar.changeAnchor(
        previousPolicy: previousPolicy,
        nextPolicy: _policy(
          version: 2,
          effectiveFrom: LocalDate(2026, 4, 1),
          anchor: Weekday.monday,
        ),
      );
      final previousCycle = WeeklyCycle.normal(
        start: LocalDate(2026, 3, 21),
        policy: previousPolicy,
      );

      expect(previousCycle.endExclusive, change.transition.start);
      expect(change.transition.endExclusive, change.firstNormalCycle.start);
    });

    test('preserves the historical policy and time zone', () {
      final parisPolicy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 3, 21),
        anchor: Weekday.saturday,
      );
      final historicalCycle = WeeklyCycle.normal(
        start: LocalDate(2026, 3, 21),
        policy: parisPolicy,
      );
      final newYorkPolicy = CyclePolicy(
        version: 2,
        effectiveFrom: LocalDate(2026, 4, 1),
        anchorWeekday: Weekday.monday,
        timeZone: IanaTimeZoneId('America/New_York'),
      );

      CycleCalendar.changeAnchor(
        previousPolicy: parisPolicy,
        nextPolicy: newYorkPolicy,
      );

      expect(historicalCycle.policy.version, 1);
      expect(historicalCycle.policy.timeZone.value, 'Europe/Paris');
      expect(historicalCycle.start, LocalDate(2026, 3, 21));
    });

    test('rejects a non-change and non-increasing policy version', () {
      final previous = _policy(
        version: 2,
        effectiveFrom: LocalDate(2026, 3, 28),
        anchor: Weekday.saturday,
      );

      expect(
        () => CycleCalendar.changeAnchor(
          previousPolicy: previous,
          nextPolicy: _policy(
            version: 3,
            effectiveFrom: LocalDate(2026, 4, 1),
            anchor: Weekday.saturday,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => CycleCalendar.changeAnchor(
          previousPolicy: previous,
          nextPolicy: _policy(
            version: 2,
            effectiveFrom: LocalDate(2026, 4, 1),
            anchor: Weekday.monday,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

CyclePolicy _policy({
  required int version,
  required LocalDate effectiveFrom,
  required Weekday anchor,
}) {
  return CyclePolicy(
    version: version,
    effectiveFrom: effectiveFrom,
    anchorWeekday: anchor,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
}

timezone.TZDateTime _midnight(LocalDate date, timezone.Location location) {
  return timezone.TZDateTime(location, date.year, date.month, date.day);
}
