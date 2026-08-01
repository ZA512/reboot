@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/browser_local_event_journal.dart';
import 'package:reboot_app/web_storage/browser_recovery_document_portal.dart';
import 'package:reboot_app/web_storage/browser_recovery_workflow.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  test(
    'exports through download and restores through file selection',
    () async {
      final source = await _profile('workflow-source', <EventRecord>[
        _householdEvent(),
      ]);
      final destination = await _profile(
        'workflow-destination',
        const <EventRecord>[],
      );
      addTearDown(() async {
        await source.delete();
        await destination.delete();
      });
      Uint8List? downloaded;
      final exportWorkflow = BrowserRecoveryWorkflow(
        documents: BrowserRecoveryDocumentPortal(
          downloadTrigger: (bytes, suggestedName) async {
            expect(suggestedName, 'reboot-test.reboot-backup');
            downloaded = bytes;
          },
        ),
      );

      final prepared = await exportWorkflow.prepareExport(source.service);
      final recoveryCode = await exportWorkflow.downloadPrepared(
        prepared: prepared,
        suggestedName: 'reboot-test.reboot-backup',
      );
      final file = web.File(
        <JSAny>[downloaded!.toJS].toJS,
        'reboot-test.reboot-backup',
        web.FilePropertyBag(type: 'application/octet-stream'),
      );
      final restoreWorkflow = BrowserRecoveryWorkflow(
        documents: BrowserRecoveryDocumentPortal(
          fileSelector: () async => file,
        ),
      );

      expect(
        await restoreWorkflow.restore(
          destination: destination.service,
          recoveryCode: recoveryCode,
        ),
        isTrue,
      );
      expect(destination.service.configuration.household, isNotNull);
      expect(await destination.service.readJournalSnapshot(), hasLength(1));
    },
  );
}

final class _TestProfile {
  const _TestProfile(this.databaseName, this.service);

  final String databaseName;
  final LocalRebootService service;

  Future<void> delete() async {
    await service.close();
    await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
      databaseName,
    );
    BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
  }
}

Future<_TestProfile> _profile(String label, List<EventRecord> events) async {
  final databaseName = 'reboot-$label-${DateTime.now().microsecondsSinceEpoch}';
  final journal = await BrowserLocalEventJournal.open(
    databaseName: databaseName,
  );
  if (events.isNotEmpty) await journal.appendAll(events);
  return _TestProfile(
    databaseName,
    await LocalRebootService.restore(journal: journal),
  );
}

EventRecord _householdEvent() => EventRecord(
  id: EventId('01960001-1111-7111-8111-000000000010'),
  recordedAtUtc: DateTime.utc(2026, 4, 1, 10),
  businessDate: LocalDate(2026, 4, 1),
  target: EntityReference(
    kind: EntityKind.household,
    id: EntityId('01960002-2222-7222-8222-000000000010'),
  ),
  payload: HouseholdCreatedPayload(
    householdKind: HouseholdKind.sharedMainAccount,
    currency: Currency.eur,
    initialCyclePolicy: CyclePolicy(
      version: 1,
      effectiveFrom: LocalDate(2026, 4, 4),
      anchorWeekday: Weekday.saturday,
      timeZone: IanaTimeZoneId('Europe/Paris'),
    ),
  ),
);
