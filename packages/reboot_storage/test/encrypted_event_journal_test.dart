import 'dart:io';
import 'dart:typed_data';

import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:reboot_storage/reboot_storage.dart';
import 'package:reboot_storage/src/database.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'reboot-storage-test-',
    );
    databasePath =
        '${temporaryDirectory.path}${Platform.pathSeparator}reboot.db';
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  group('encrypted database opening', () {
    test(
      'creates an opaque file and reopens it only with the exact key',
      () async {
        final journal = await RebootEventJournal.open(
          filePath: databasePath,
          key: _key(1),
        );
        await journal.append(_householdEvent(1));
        await journal.close();

        final header = await File(databasePath).openRead(0, 16).first;
        expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));

        final reopened = await RebootEventJournal.open(
          filePath: databasePath,
          key: _key(1),
        );
        expect(await reopened.readAll(), hasLength(1));
        await reopened.close();

        expect(
          () => RebootEventJournal.open(filePath: databasePath, key: _key(2)),
          throwsA(isA<EncryptedStorageOpenException>()),
        );
      },
    );

    test('requires an absolute path and an exact 256-bit key', () {
      expect(() => EncryptedDatabaseKey(Uint8List(31)), throwsArgumentError);
      expect(
        () => RebootEventJournal.open(filePath: 'relative.db', key: _key(1)),
        throwsArgumentError,
      );
    });

    test('destroys transient key material explicitly', () {
      final key = _key(1)..destroy();

      expect(key.copyBytes, throwsStateError);
      expect(key.destroy, returnsNormally);
    });

    test('enables and verifies required SQLite settings', () async {
      final database = await RebootDatabase.open(
        filePath: databasePath,
        key: _key(1),
      );

      expect(await _pragma(database, 'foreign_keys'), 1);
      expect(await _pragma(database, 'journal_mode'), 'wal');
      expect(await _pragma(database, 'synchronous'), 2);
      expect(await _pragma(database, 'temp_store'), 2);
      expect(await _pragma(database, 'hmac_check'), '1');
      expect(await _pragma(database, 'cipher'), 'chacha20');
      await database.close();
    });
  });

  group('append-only journal', () {
    test('persists and restores the application command flow', () async {
      final journal = await RebootEventJournal.open(
        filePath: databasePath,
        key: _key(7),
      );
      final service = await LocalRebootService.restore(journal: journal);
      await service.initializeHousehold(
        InitializeHouseholdCommand(
          householdKind: HouseholdKind.sharedMainAccount,
          onboardingDate: LocalDate(2026, 4, 1),
          anchorWeekday: Weekday.saturday,
          timeZone: IanaTimeZoneId('Europe/Paris'),
          firstCycleChoice: FirstCycleStartChoice.nextAnchor,
        ),
      );
      final expenseResult = await service.recordExpense(
        RecordExpenseCommand(
          amount: Money.fromMinorUnits(2800, Currency.eur),
          label: 'Courses',
          purchaseDate: LocalDate(2026, 4, 5),
          allocationCycleCount: 3,
        ),
      );
      final reserve = await service.createReserve(
        CreateReserveCommand(
          name: 'Imprévus',
          kind: ReserveKind.real,
          openingBalance: Money.fromMinorUnits(50000, Currency.eur),
          businessDate: LocalDate(2026, 4, 5),
        ),
      );
      await service.useReserve(
        UseReserveCommand(
          reserveId: reserve.id,
          amount: Money.fromMinorUnits(12000, Currency.eur),
          label: 'Vétérinaire',
          purchaseDate: LocalDate(2026, 4, 6),
        ),
      );
      await service.recordExpenseRefund(
        RecordExpenseRefundCommand(
          expenseId: expenseResult.expenseId,
          amount: Money.fromMinorUnits(800, Currency.eur),
          receivedDate: LocalDate(2026, 4, 6),
        ),
      );
      await service.configureHealthTracking(
        ConfigureHealthTrackingCommand(
          enabled: true,
          delayWeeks: 4,
          alertThreshold: Money.fromMinorUnits(5000, Currency.eur),
          businessDate: LocalDate(2026, 4, 5),
        ),
      );
      await service.recordHealthEntry(
        RecordHealthEntryCommand(
          kind: HealthEntryKind.expense,
          amount: Money.fromMinorUnits(10000, Currency.eur),
          label: 'Consultations',
          businessDate: LocalDate(2026, 4, 5),
        ),
      );
      await service.recordHealthEntry(
        RecordHealthEntryCommand(
          kind: HealthEntryKind.reimbursement,
          amount: Money.fromMinorUnits(3000, Currency.eur),
          label: 'Remboursements avril',
          businessDate: LocalDate(2026, 4, 20),
        ),
      );
      await service.close();

      final reopenedJournal = await RebootEventJournal.open(
        filePath: databasePath,
        key: _key(7),
      );
      final restored = await LocalRebootService.restore(
        journal: reopenedJournal,
      );

      expect(restored.configuration.household, isNotNull);
      final expense = restored.expenses.activeExpenses.single;
      expect(expense.label, 'Courses');
      expect(expense.allocations!.map((part) => part.amount.minorUnits), [
        933,
        933,
        934,
      ]);
      expect(expense.refundedAmount.minorUnits, 800);
      final restoredReserve = restored.reserves.reserves.values.single;
      expect(restoredReserve.kind, ReserveKind.real);
      expect(restoredReserve.balance.minorUnits, 38000);
      expect(
        restored.health.tracking!.estimatedRest(LocalDate(2026, 5, 3)),
        Money.fromMinorUnits(7000, Currency.eur),
      );
      await restored.close();
    });

    test('assigns monotone positions and replays both projections', () async {
      final journal = await RebootEventJournal.open(
        filePath: databasePath,
        key: _key(3),
      );
      final entries = await journal.appendAll([
        _householdEvent(1),
        _cashFlowEvent(2),
        _expenseEvent(3),
        _allocationEvent(4),
      ]);

      expect(entries.map((entry) => entry.position.value), [1, 2, 3, 4]);
      final restored = await journal.readAll();
      expect(restored.map((entry) => entry.event.eventType), [
        'household.created',
        'cash-flow.created',
        'expense.recorded',
        'expense.allocations.planned',
      ]);
      expect(ConfigurationLedger.replay(restored).cashFlows, hasLength(1));
      expect(ExpenseLedger.replay(restored).activeExpenses, hasLength(1));
      await journal.close();
    });

    test('is idempotent for identical UUIDs', () async {
      final journal = await RebootEventJournal.open(
        filePath: databasePath,
        key: _key(4),
      );
      final event = _householdEvent(1);
      final first = await journal.append(event);
      final repeated = await journal.append(event);

      expect(repeated.position, first.position);
      expect(await journal.readAll(), hasLength(1));
      await journal.close();
    });

    test('rolls back a batch when one UUID has conflicting content', () async {
      final journal = await RebootEventJournal.open(
        filePath: databasePath,
        key: _key(5),
      );
      await journal.append(_householdEvent(1));

      expect(
        () => journal.appendAll([
          _cashFlowEvent(2),
          EventRecord(
            id: _eventId(1),
            recordedAtUtc: DateTime.utc(2026, 4, 1, 11),
            businessDate: LocalDate(2026, 4, 1),
            target: EntityReference(
              kind: EntityKind.household,
              id: _householdId,
            ),
            payload: HouseholdCreatedPayload(
              householdKind: HouseholdKind.solo,
              currency: Currency.eur,
              initialCyclePolicy: _policy,
            ),
          ),
        ]),
        throwsA(isA<JournalEventConflictException>()),
      );
      expect(await journal.readAll(), hasLength(1));
      await journal.close();
    });

    test('SQLite triggers reject UPDATE and DELETE', () async {
      final database = await RebootDatabase.open(
        filePath: databasePath,
        key: _key(6),
      );
      await database.customStatement('''
        INSERT INTO local_events (
          event_id, recorded_at_utc_micros, business_date, entity_kind,
          entity_id, event_type, event_schema_version, payload_json
        ) VALUES (
          '01950001-5555-7555-8555-555555555555', 1, '2026-04-01',
          'expense', '01960001-6666-7666-8666-666666666666',
          'expense.deleted', 1, '{}'
        )
      ''');

      expect(
        () => database.customStatement(
          "UPDATE local_events SET business_date = '2026-04-02'",
        ),
        throwsA(anything),
      );
      expect(
        () => database.customStatement('DELETE FROM local_events'),
        throwsA(anything),
      );
      final count = await database
          .customSelect('SELECT count(*) AS count FROM local_events')
          .getSingle();
      expect(count.read<int>('count'), 1);
      await database.close();
    });
  });
}

Future<Object?> _pragma(RebootDatabase database, String name) async {
  final row = await database.customSelect('PRAGMA $name').getSingle();
  return row.data.values.single;
}

EncryptedDatabaseKey _key(int seed) {
  return EncryptedDatabaseKey(
    Uint8List.fromList(List<int>.generate(32, (index) => seed + index)),
  );
}

final EntityId _householdId = EntityId('01960001-6666-7666-8666-666666666666');
final EntityId _cashFlowId = EntityId('01960002-6666-7666-8666-666666666666');
final EntityId _expenseId = EntityId('01960003-6666-7666-8666-666666666666');
final CyclePolicy _policy = CyclePolicy(
  version: 1,
  effectiveFrom: LocalDate(2026, 4, 4),
  anchorWeekday: Weekday.saturday,
  timeZone: IanaTimeZoneId('Europe/Paris'),
);

EventRecord _householdEvent(int identity) {
  return EventRecord(
    id: _eventId(identity),
    recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, identity),
    businessDate: LocalDate(2026, 4, 1),
    target: EntityReference(kind: EntityKind.household, id: _householdId),
    payload: HouseholdCreatedPayload(
      householdKind: HouseholdKind.sharedMainAccount,
      currency: Currency.eur,
      initialCyclePolicy: _policy,
    ),
  );
}

EventRecord _cashFlowEvent(int identity) {
  return EventRecord(
    id: _eventId(identity),
    recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, identity),
    businessDate: LocalDate(2026, 4, 1),
    target: EntityReference(kind: EntityKind.cashFlow, id: _cashFlowId),
    payload: CashFlowCreatedPayload(
      definition: CashFlowDefinition.fixed(
        title: 'Salaire 1',
        direction: CashFlowDirection.income,
        schedule: RecurringSchedule(
          firstOccurrence: LocalDate(2026, 4, 30),
          frequency: RecurrenceFrequency.monthly,
        ),
        amountPerOccurrence: Money.fromMinorUnits(300000, Currency.eur),
      ),
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
    ),
  );
}

EventRecord _expenseEvent(int identity) {
  return EventRecord(
    id: _eventId(identity),
    recordedAtUtc: DateTime.utc(2026, 4, 5, 10, 0, identity),
    businessDate: LocalDate(2026, 4, 5),
    target: EntityReference(kind: EntityKind.expense, id: _expenseId),
    payload: ExpenseRecordedPayload(
      amount: Money.fromMinorUnits(4250, Currency.eur),
      label: 'Courses',
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: LocalDate(2026, 4, 4),
        policyVersion: 1,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
  );
}

EventRecord _allocationEvent(int identity) {
  return EventRecord(
    id: _eventId(identity),
    recordedAtUtc: DateTime.utc(2026, 4, 5, 10, 1, identity),
    businessDate: LocalDate(2026, 4, 5),
    target: EntityReference(kind: EntityKind.expense, id: _expenseId),
    payload: ExpenseAllocationsPlannedPayload.evenly(
      expenseAmount: Money.fromMinorUnits(4250, Currency.eur),
      cycleStarts: [LocalDate(2026, 4, 4)],
    ),
  );
}

EventId _eventId(int value) => EventId(
  '0195${value.toString().padLeft(4, '0')}-5555-7555-8555-555555555555',
);
