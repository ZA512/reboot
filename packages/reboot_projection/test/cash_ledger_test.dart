import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  test('cash method changes do not reinterpret older dates', () {
    final ledger = CashLedger.replay([
      _entry(
        1,
        LocalDate(2026, 4, 1),
        const CashHandlingMethodSetPayload(
          method: CashWithdrawalMethod.withdrawalAsExpense,
        ),
      ),
      _entry(
        2,
        LocalDate(2026, 5, 1),
        const CashHandlingMethodSetPayload(
          method: CashWithdrawalMethod.cashWallet,
        ),
      ),
    ]);

    expect(
      ledger.methodOn(LocalDate(2026, 4, 30)),
      CashWithdrawalMethod.withdrawalAsExpense,
    );
    expect(
      ledger.methodOn(LocalDate(2026, 5, 1)),
      CashWithdrawalMethod.cashWallet,
    );
  });

  test(
    'wallet transfers require the method and remain auditable when reversed',
    () {
      final transfer = CashWalletTransferRecordedPayload(
        amount: Money.fromMinorUnits(5000, Currency.eur),
        label: 'Retrait espèces',
      );
      final ledger = CashLedger.replay([
        _entry(
          1,
          LocalDate(2026, 4, 1),
          const CashHandlingMethodSetPayload(
            method: CashWithdrawalMethod.cashWallet,
          ),
        ),
        _entry(2, LocalDate(2026, 4, 2), transfer),
        _entry(
          3,
          LocalDate(2026, 4, 2),
          CashWalletTransferReversedPayload(transferEventId: _eventId(2)),
        ),
      ]);

      expect(ledger.walletTransfers, hasLength(1));
      expect(ledger.walletTransfers.single.isReversed, isTrue);
      expect(ledger.activeWalletTransfers, isEmpty);
      expect(
        () => CashLedger.replay([_entry(1, LocalDate(2026, 4, 1), transfer)]),
        throwsA(isA<ProjectionConflictException>()),
      );
    },
  );
}

LocalJournalEntry _entry(int position, LocalDate date, EventPayload payload) =>
    LocalJournalEntry(
      position: LocalJournalPosition(position),
      event: EventRecord(
        id: _eventId(position),
        recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, position),
        businessDate: date,
        target: EntityReference(kind: EntityKind.cashHandling, id: _cashId),
        payload: payload,
      ),
    );

final _cashId = EntityId('018f2b8a-7d3c-7a1b-8c4d-1234567890ac');

EventId _eventId(int value) =>
    EventId('018f2b8a-7d3c-7a1b-8c4d-${value.toString().padLeft(12, '0')}');
