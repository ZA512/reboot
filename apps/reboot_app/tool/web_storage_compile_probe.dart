import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/browser_local_event_journal.dart';
import 'package:reboot_app/web_storage/browser_recovery_archive.dart';
import 'package:reboot_app/web_storage/browser_storage_durability.dart';
import 'package:reboot_app/web_storage/encrypted_projection_snapshot.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

Future<void> main(List<String> arguments) async {
  // Runtime arguments deliberately keep every browser-only path reachable for
  // both JavaScript and Wasm compilation; compile-time false probes get removed
  // by tree shaking and therefore prove nothing.
  if (arguments.isEmpty) return;
  if (arguments.length > 1) await inspectWebStorageDurability();
  final databaseName = arguments.first;
  final domainJournal = await BrowserLocalEventJournal.open(
    databaseName: databaseName,
  );
  final entries = await domainJournal.appendAll(<EventRecord>[
    EventRecord(
      id: EventId('018f1f3a-7b1c-7a2d-8e3f-000000000001'),
      recordedAtUtc: DateTime.utc(2026, 8, 1),
      businessDate: LocalDate(2026, 8, 1),
      target: EntityReference(
        kind: EntityKind.expense,
        id: EntityId('018f1f3a-7b1c-7a2d-8e3f-000000000002'),
      ),
      payload: const ExpenseDeletedPayload(),
    ),
  ]);
  final service = await LocalRebootService.restore(journal: domainJournal);
  final recovery = await BrowserRecoveryArchiveService().prepare(service);
  if (recovery.bytes.isEmpty || recovery.recoveryCode.isEmpty) {
    throw StateError('The recovery compile probe produced no archive.');
  }
  await service.close();

  final journal = await BrowserEncryptedJournalPrototype.open(
    databaseName: databaseName,
  );
  try {
    final position = entries.single.position.exactValue;
    await journal.writeProjectionSnapshot(
      WebPrototypeProjectionSnapshot(
        journalPosition: position,
        schemaVersion: 1,
        projectionJson: '{"synthetic":true}',
      ),
    );
    await journal.readProjectionSnapshot();
    await journal.readAfter(position);
  } finally {
    journal.close();
  }
}
