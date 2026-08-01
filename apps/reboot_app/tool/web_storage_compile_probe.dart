import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/browser_storage_durability.dart';
import 'package:reboot_app/web_storage/encrypted_event_envelope.dart';
import 'package:reboot_app/web_storage/encrypted_projection_snapshot.dart';

Future<void> main(List<String> arguments) async {
  // Runtime arguments deliberately keep every browser-only path reachable for
  // both JavaScript and Wasm compilation; compile-time false probes get removed
  // by tree shaking and therefore prove nothing.
  if (arguments.isEmpty) return;
  if (arguments.length > 1) await inspectWebStorageDurability();
  final databaseName = arguments.first;
  final journal = await BrowserEncryptedJournalPrototype.open(
    databaseName: databaseName,
  );
  try {
    final position = await journal.append(
      WebPrototypePlainEvent(
        eventId: '018f1f3a-7b1c-7a2d-8e3f-000000000001',
        eventType: 'prototype.compile-probe',
        schemaVersion: 1,
        payloadJson: '{"synthetic":true}',
      ),
    );
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
