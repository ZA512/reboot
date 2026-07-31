import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('HealthLedger', () {
    test('matures expenses after the delay and subtracts reimbursements', () {
      final ledger = HealthLedger.replay([
        _entry(
          1,
          LocalDate(2026, 4, 1),
          HealthTrackingConfiguredPayload(
            enabled: true,
            delayWeeks: 4,
            alertThreshold: _eur(5000),
          ),
        ),
        _entry(
          2,
          LocalDate(2026, 4, 1),
          HealthExpenseRecordedPayload(
            amount: _eur(10000),
            label: 'Santé avril',
          ),
        ),
        _entry(
          3,
          LocalDate(2026, 4, 20),
          HealthReimbursementRecordedPayload(
            amount: _eur(3000),
            label: 'Remboursements avril',
          ),
        ),
      ]);
      final tracking = ledger.tracking!;

      expect(tracking.estimatedRest(LocalDate(2026, 4, 28)).minorUnits, -3000);
      expect(tracking.estimatedRest(LocalDate(2026, 4, 29)).minorUnits, 7000);
      expect(tracking.requiresAttention(LocalDate(2026, 4, 29)), isTrue);
    });

    test('subtracts handled amounts and alerts only above the threshold', () {
      final ledger = HealthLedger.replay([
        _configured(1),
        _entry(
          2,
          LocalDate(2026, 4, 1),
          HealthExpenseRecordedPayload(amount: _eur(10000), label: 'Dépenses'),
        ),
        _entry(
          3,
          LocalDate(2026, 4, 30),
          HealthRegularizationRecordedPayload(
            amount: _eur(5000),
            label: 'Déjà compensé',
          ),
        ),
      ]);
      final tracking = ledger.tracking!;

      expect(tracking.estimatedRest(LocalDate(2026, 5, 1)).minorUnits, 5000);
      expect(tracking.requiresAttention(LocalDate(2026, 5, 1)), isFalse);
    });

    test('starts a fresh estimation epoch after re-enabling', () {
      final ledger = HealthLedger.replay([
        _configured(1),
        _entry(
          2,
          LocalDate(2026, 4, 1),
          HealthExpenseRecordedPayload(
            amount: _eur(10000),
            label: 'Ancienne dépense',
          ),
        ),
        _entry(
          3,
          LocalDate(2026, 5, 1),
          HealthTrackingConfiguredPayload(
            enabled: false,
            delayWeeks: 4,
            alertThreshold: _eur(5000),
          ),
        ),
        _entry(
          4,
          LocalDate(2026, 6, 1),
          HealthTrackingConfiguredPayload(
            enabled: true,
            delayWeeks: 4,
            alertThreshold: _eur(5000),
          ),
        ),
      ]);

      expect(ledger.tracking!.trackingStartDate, LocalDate(2026, 6, 1));
      expect(
        ledger.tracking!.estimatedRest(LocalDate(2026, 7, 1)),
        Money.zero(Currency.eur),
      );
    });
  });
}

LocalJournalEntry _configured(int position) => _entry(
  position,
  LocalDate(2026, 4, 1),
  HealthTrackingConfiguredPayload(
    enabled: true,
    delayWeeks: 4,
    alertThreshold: _eur(5000),
  ),
);

LocalJournalEntry _entry(int position, LocalDate date, EventPayload payload) =>
    LocalJournalEntry(
      position: LocalJournalPosition(position),
      event: EventRecord(
        id: _eventId(position),
        recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, position),
        businessDate: date,
        target: EntityReference(kind: EntityKind.healthTracking, id: _healthId),
        payload: payload,
      ),
    );

final _healthId = EntityId('018f2b8a-7d3c-7a1b-8c4d-1234567890ab');

EventId _eventId(int value) =>
    EventId('018f2b8a-7d3c-7a1b-8c4d-${value.toString().padLeft(12, '0')}');

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
