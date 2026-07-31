import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('TrendProjection', () {
    test('uses each historical budget and the selected trailing window', () {
      final cycles = _normalCycles(10);
      final projection = TrendProjection.build([
        for (var index = 0; index < cycles.length; index++)
          TrendCycleObservation(
            cycle: cycles[index],
            budget: _eur(index < 5 ? 10000 : 20000),
            allocatedExpenses: _eur(index < 5 ? 9000 : 18000),
          ),
      ]);

      expect(projection.observedCycles, hasLength(10));
      expect(projection.totalBudget.minorUnits, 150000);
      expect(projection.totalAllocatedExpenses.minorUnits, 135000);
      expect(projection.balance.minorUnits, 15000);
      expect(projection.window(4).observedCycles, hasLength(4));
      expect(projection.window(4).totalBudget.minorUnits, 80000);
      expect(projection.window(4).balance.minorUnits, 8000);
      expect(projection.window(52).observedCycles, hasLength(10));
    });

    test('classifies the exact 5 and 15 percent boundaries', () {
      expect(
        _latestSeverity(budget: 10000, expense: 10499),
        TrendAlertSeverity.none,
      );
      expect(
        _latestSeverity(budget: 10000, expense: 10500),
        TrendAlertSeverity.vigilance,
      );
      expect(
        _latestSeverity(budget: 10000, expense: 11499),
        TrendAlertSeverity.vigilance,
      );
      expect(
        _latestSeverity(budget: 10000, expense: 11500),
        TrendAlertSeverity.strong,
      );
    });

    test('keeps a strong recent warning separate from a healthy balance', () {
      final cycles = _normalCycles(4);
      final projection = TrendProjection.build([
        for (var index = 0; index < cycles.length; index++)
          TrendCycleObservation(
            cycle: cycles[index],
            budget: _eur(10000),
            allocatedExpenses: _eur(index == 3 ? 13000 : 0),
          ),
      ]);

      expect(projection.latestOverspend.minorUnits, 3000);
      expect(projection.latestOverspendRatio!.basisPoints, 3000);
      expect(
        projection.latestOverspendRatio!.severity,
        TrendAlertSeverity.strong,
      );
      expect(projection.balance.minorUnits, 27000);
      expect(projection.cumulativeNegativeRatio, isNull);
      expect(projection.severity, TrendAlertSeverity.strong);
    });

    test('excludes an exceptional transition from normal trends', () {
      final previous = _policy(
        version: 1,
        start: LocalDate(2026, 3, 21),
        weekday: Weekday.saturday,
      );
      final change = CycleCalendar.changeAnchor(
        previousPolicy: previous,
        nextPolicy: _policy(
          version: 2,
          start: LocalDate(2026, 4, 1),
          weekday: Weekday.monday,
        ),
      );
      final projection = TrendProjection.build([
        TrendCycleObservation(
          cycle: WeeklyCycle.normal(
            start: LocalDate(2026, 3, 21),
            policy: previous,
          ),
          budget: _eur(20000),
          allocatedExpenses: _eur(10000),
        ),
        TrendCycleObservation(
          cycle: change.transition,
          budget: _eur(20000),
          allocatedExpenses: _eur(40000),
        ),
        TrendCycleObservation(
          cycle: change.firstNormalCycle,
          budget: _eur(20000),
          allocatedExpenses: _eur(15000),
        ),
      ]);

      expect(projection.excludedTransitionCount, 1);
      expect(
        projection.excludedTransitionCycles.single.cycle,
        change.transition,
      );
      expect(projection.observedCycles, hasLength(2));
      expect(projection.balance.minorUnits, 15000);
      expect(projection.severity, TrendAlertSeverity.none);
    });

    test('keeps at most the latest 52 normal cycles', () {
      final cycles = _normalCycles(60);
      final projection = TrendProjection.build([
        for (var index = 0; index < cycles.length; index++)
          TrendCycleObservation(
            cycle: cycles[index],
            budget: _eur(10000),
            allocatedExpenses: _eur(index * 100),
          ),
      ]);

      expect(projection.observedCycles, hasLength(52));
      expect(projection.observedCycles.first.cycle, cycles[8]);
      expect(projection.observedCycles.last.cycle, cycles.last);
    });

    test('rejects unsupported windows and unordered observations', () {
      final cycles = _normalCycles(2);
      final projection = TrendProjection.build([
        _observation(cycles[0]),
        _observation(cycles[1]),
      ]);

      expect(() => projection.window(12), throwsArgumentError);
      expect(
        () => TrendProjection.build([
          _observation(cycles[1]),
          _observation(cycles[0]),
        ]),
        throwsArgumentError,
      );
    });
  });
}

TrendAlertSeverity _latestSeverity({
  required int budget,
  required int expense,
}) {
  final cycle = _normalCycles(1).single;
  return TrendProjection.build([
    TrendCycleObservation(
      cycle: cycle,
      budget: _eur(budget),
      allocatedExpenses: _eur(expense),
    ),
  ]).severity;
}

TrendCycleObservation _observation(WeeklyCycle cycle) {
  return TrendCycleObservation(
    cycle: cycle,
    budget: _eur(10000),
    allocatedExpenses: _eur(9000),
  );
}

List<WeeklyCycle> _normalCycles(int count) {
  final policy = _policy(
    version: 1,
    start: LocalDate(2025, 1, 4),
    weekday: Weekday.saturday,
  );
  return CycleCalendar.normalCycles(
    firstStart: LocalDate(2025, 1, 4),
    count: count,
    policy: policy,
  );
}

CyclePolicy _policy({
  required int version,
  required LocalDate start,
  required Weekday weekday,
}) {
  return CyclePolicy(
    version: version,
    effectiveFrom: start,
    anchorWeekday: weekday,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
