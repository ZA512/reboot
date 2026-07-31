import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('ReserveLedger', () {
    test('replays opening balance, funding, and reserve-funded expense', () {
      final ledger = ReserveLedger.replay([
        _entry(
          1,
          ReserveCreatedPayload(
            name: 'Imprévus',
            kind: ReserveKind.real,
            openingBalance: _eur(50000),
          ),
        ),
        _entry(
          2,
          ReserveFundsAddedPayload(amount: _eur(12000), label: 'Surplus'),
        ),
        _entry(
          3,
          ReserveExpenseRecordedPayload(
            amount: _eur(8000),
            label: 'Vétérinaire',
          ),
        ),
      ]);

      final reserve = ledger.reserves.values.single;
      expect(reserve.balance.minorUnits, 54000);
      expect(reserve.activeMovements, hasLength(2));
      expect(ledger.totalBalance, reserve.balance);
    });

    test('reverses an expense without erasing its audit history', () {
      final expenseId = _eventId(3);
      final ledger = ReserveLedger.replay([
        _entry(
          1,
          ReserveCreatedPayload(
            name: 'Virtuelle',
            kind: ReserveKind.virtual,
            openingBalance: _eur(10000),
          ),
        ),
        _entry(
          3,
          ReserveExpenseRecordedPayload(amount: _eur(4000), label: 'Erreur'),
        ),
        _entry(4, ReserveMovementReversedPayload(movementEventId: expenseId)),
      ]);

      final reserve = ledger.reserves.values.single;
      expect(reserve.balance.minorUnits, 10000);
      expect(reserve.movements.single.isReversed, isTrue);
      expect(reserve.activeMovements, isEmpty);
    });

    test('refuses reserve overdrafts and unsafe funding reversals', () {
      final created = _entry(
        1,
        ReserveCreatedPayload(
          name: 'Secours',
          kind: ReserveKind.real,
          openingBalance: _eur(5000),
        ),
      );
      expect(
        () => ReserveLedger.replay([
          created,
          _entry(
            2,
            ReserveExpenseRecordedPayload(
              amount: _eur(5001),
              label: 'Trop élevé',
            ),
          ),
        ]),
        throwsA(isA<InsufficientReserveBalanceException>()),
      );

      final fundingId = _eventId(2);
      expect(
        () => ReserveLedger.replay([
          created,
          _entry(
            2,
            ReserveFundsAddedPayload(amount: _eur(5000), label: 'Apport'),
          ),
          _entry(
            3,
            ReserveExpenseRecordedPayload(amount: _eur(8000), label: 'Dépense'),
          ),
          _entry(4, ReserveMovementReversedPayload(movementEventId: fundingId)),
        ]),
        throwsA(isA<InsufficientReserveBalanceException>()),
      );
    });
  });
}

LocalJournalEntry _entry(int position, EventPayload payload) =>
    LocalJournalEntry(
      position: LocalJournalPosition(position),
      event: EventRecord(
        id: _eventId(position),
        recordedAtUtc: DateTime.utc(2026, 4, position),
        businessDate: LocalDate(2026, 4, position),
        target: EntityReference(kind: EntityKind.reserve, id: _reserveId),
        payload: payload,
      ),
    );

final _reserveId = EntityId('018f2b8a-7d3c-7a1b-8c4d-1234567890ab');

EventId _eventId(int value) =>
    EventId('018f2b8a-7d3c-7a1b-8c4d-${value.toString().padLeft(12, '0')}');

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
