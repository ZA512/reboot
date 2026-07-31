import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_storage/reboot_storage.dart';

import 'local_profile_bootstrap.dart';

/// Platform Keychain or Keystore boundary.
final secureValueStoreProvider = Provider<SecureValueStore>(
  (ref) => FlutterSecureValueStore(),
);

/// Private application-support location for the encrypted profile.
final supportDirectoryProvider = FutureProvider<Directory>(
  (ref) => getApplicationSupportDirectory(),
);

/// CSPRNG boundary for a new installation-local database key.
final databaseKeyGeneratorProvider = Provider<DatabaseKeyMaterialGenerator>(
  (ref) => SecureDatabaseKeyMaterialGenerator(),
);

/// Concrete encrypted journal boundary.
final localJournalOpenerProvider = Provider<LocalJournalOpener>(
  (ref) => (filePath, key) {
    return RebootEventJournal.open(filePath: filePath, key: key);
  },
);

/// Fully restored local application service.
final localRebootServiceProvider = FutureProvider<LocalRebootService>((
  ref,
) async {
  final directory = await ref.watch(supportDirectoryProvider.future);
  final bootstrap = LocalProfileBootstrap(
    secureValues: ref.watch(secureValueStoreProvider),
    supportDirectory: () async => directory,
    keyGenerator: ref.watch(databaseKeyGeneratorProvider),
    openJournal: ref.watch(localJournalOpenerProvider),
  );
  final service = await bootstrap.open();
  ref.onDispose(() => unawaited(service.close()));
  return service;
});
