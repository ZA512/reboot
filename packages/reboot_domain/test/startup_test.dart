import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  group('LiquiditySnapshot', () {
    test('separates booked balance from money already committed', () {
      final snapshot = LiquiditySnapshot(
        capturedAtUtc: DateTime.utc(2026, 8, 2, 8),
        bookedBalance: _eur(100000),
        pendingCardAmount: _eur(12000),
        deferredCardAmount: _eur(8000),
        outstandingCheques: _eur(5000),
        committedTransfers: _eur(3000),
        protectedVirtualAllocations: _eur(22000),
        source: LiquiditySnapshotSource.manual,
        confidence: StartupDataConfidence.high,
      );

      expect(snapshot.usableCash, _eur(50000));
    });

    test('accepts a real negative available position', () {
      final snapshot = LiquiditySnapshot(
        capturedAtUtc: DateTime.utc(2026, 8, 2, 8),
        bookedBalance: _eur(-150000),
        pendingCardAmount: _eur(10000),
        source: LiquiditySnapshotSource.manual,
        confidence: StartupDataConfidence.medium,
      );

      expect(snapshot.usableCash, _eur(-160000));
    });

    test('rejects local timestamps and negative committed amounts', () {
      expect(
        () => LiquiditySnapshot(
          capturedAtUtc: DateTime(2026, 8, 2),
          bookedBalance: _eur(0),
          source: LiquiditySnapshotSource.manual,
          confidence: StartupDataConfidence.low,
        ),
        throwsArgumentError,
      );
      expect(
        () => LiquiditySnapshot(
          capturedAtUtc: DateTime.utc(2026, 8, 2),
          bookedBalance: _eur(0),
          committedTransfers: _eur(-1),
          source: LiquiditySnapshotSource.manual,
          confidence: StartupDataConfidence.low,
        ),
        throwsArgumentError,
      );
    });
  });

  group('HouseholdNeedsProfile', () {
    test('one full-time adult equals exactly one consumption unit', () {
      final profile = _profile(adults: 1, children: 0);

      expect(profile.personCount, 1);
      expect(profile.consumptionUnitMilliUnits, 1000);
    });

    test('one adult and two young children equal 1.6 units', () {
      final profile = _profile(adults: 1, children: 2);

      expect(profile.personCount, 3);
      expect(profile.consumptionUnitMilliUnits, 1600);
    });

    test('weights optional partial presence without using floating point', () {
      final profile = HouseholdNeedsProfile(
        fullTimePersons14OrOlder: 1,
        fullTimeChildrenUnder14: 0,
        partialPresences: [
          PartialHouseholdPresence(
            ageBand: HouseholdNeedAgeBand.age14OrOlder,
            presencePermille: 500,
          ),
          PartialHouseholdPresence(
            ageBand: HouseholdNeedAgeBand.under14,
            presencePermille: 500,
          ),
        ],
        weeklyBudgetScope: const {WeeklyBudgetCategory.groceries},
        minimumViableWeeklyBudget: _eur(5000),
      );

      expect(profile.personCount, 3);
      expect(profile.consumptionUnitMilliUnits, 1400);
    });
  });
}

HouseholdNeedsProfile _profile({required int adults, required int children}) {
  return HouseholdNeedsProfile(
    fullTimePersons14OrOlder: adults,
    fullTimeChildrenUnder14: children,
    weeklyBudgetScope: const {
      WeeklyBudgetCategory.groceries,
      WeeklyBudgetCategory.hygiene,
    },
    minimumViableWeeklyBudget: _eur(5000),
  );
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
