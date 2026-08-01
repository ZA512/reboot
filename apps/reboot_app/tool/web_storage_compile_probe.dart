import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';

Future<void> main() async {
  const databaseName = String.fromEnvironment('REBOOT_WEB_PROBE_DATABASE');
  if (databaseName.isEmpty) return;
  final journal = await BrowserEncryptedJournalPrototype.open(
    databaseName: databaseName,
  );
  journal.close();
}
