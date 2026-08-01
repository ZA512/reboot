import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/browser_storage_durability.dart';

Future<void> main() async {
  const inspectDurability = bool.fromEnvironment('REBOOT_WEB_PROBE_DURABILITY');
  if (inspectDurability) await inspectWebStorageDurability();

  const databaseName = String.fromEnvironment('REBOOT_WEB_PROBE_DATABASE');
  if (databaseName.isEmpty) return;
  final journal = await BrowserEncryptedJournalPrototype.open(
    databaseName: databaseName,
  );
  journal.close();
}
