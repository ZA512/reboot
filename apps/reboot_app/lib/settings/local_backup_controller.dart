import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_storage/reboot_storage.dart';

import '../infrastructure/local_backup_archive.dart';
import '../infrastructure/local_backup_document_portal.dart';
import '../infrastructure/local_profile_bootstrap.dart';

final localBackupArchiveServiceProvider = Provider<LocalBackupArchive>(
  (ref) => LocalBackupArchiveService(
    temporaryDirectory: getTemporaryDirectory,
    keyGenerator: SecureDatabaseKeyMaterialGenerator(),
    openJournal: (filePath, key) =>
        RebootEventJournal.open(filePath: filePath, key: key),
  ),
);

final localBackupDocumentPortalProvider = Provider<LocalBackupDocumentPortal>(
  (ref) => const AndroidLocalBackupDocumentPortal(),
);

final localBackupControllerProvider =
    AsyncNotifierProvider<LocalBackupController, int>(
      LocalBackupController.new,
    );

/// Serializes explicit export and restore operations.
final class LocalBackupController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<String?> export({
    required LocalRebootService service,
    required String suggestedName,
  }) async {
    if (state.isLoading) return null;
    final revision = state.value ?? 0;
    state = const AsyncLoading();
    PreparedLocalBackup? backup;
    try {
      final archives = ref.read(localBackupArchiveServiceProvider);
      backup = await archives.prepare(service);
      final saved = await ref
          .read(localBackupDocumentPortalProvider)
          .save(source: backup.file, suggestedName: suggestedName);
      state = AsyncData(revision + 1);
      return saved ? backup.recoveryCode : null;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    } finally {
      if (backup != null) {
        await ref.read(localBackupArchiveServiceProvider).discard(backup);
      }
    }
  }

  Future<bool> restore({
    required LocalRebootService service,
    required String recoveryCode,
  }) async {
    if (state.isLoading) return false;
    final revision = state.value ?? 0;
    state = const AsyncLoading();
    File? selected;
    try {
      selected = await ref.read(localBackupDocumentPortalProvider).pick();
      if (selected == null) {
        state = AsyncData(revision + 1);
        return false;
      }
      await ref
          .read(localBackupArchiveServiceProvider)
          .restore(
            destination: service,
            file: selected,
            recoveryCode: recoveryCode,
          );
      state = AsyncData(revision + 1);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    } finally {
      if (selected != null) {
        try {
          if (await selected.exists()) await selected.delete();
        } on Object {
          // The selected copy lives only in the private operating-system cache.
        }
      }
    }
  }
}
