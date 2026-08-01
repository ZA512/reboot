import 'package:reboot_application/reboot_application.dart';

import 'browser_recovery_archive.dart';
import 'browser_recovery_document_portal.dart';

/// Coordinates one explicit PWA backup export or first-run restoration.
final class BrowserRecoveryWorkflow {
  BrowserRecoveryWorkflow({
    BrowserRecoveryArchiveService? archives,
    BrowserRecoveryDocumentPortal? documents,
  }) : _archives = archives ?? BrowserRecoveryArchiveService(),
       _documents = documents ?? BrowserRecoveryDocumentPortal();

  final BrowserRecoveryArchiveService _archives;
  final BrowserRecoveryDocumentPortal _documents;
  bool _busy = false;

  /// Encrypts the current journal before the user starts the download.
  Future<BrowserPreparedRecoveryArchive> prepareExport(
    LocalRebootService service,
  ) {
    return _runExclusive(() => _archives.prepare(service));
  }

  /// Starts a prepared download synchronously from a fresh user action.
  ///
  /// Keeping this separate from [prepareExport] preserves the transient user
  /// activation required by stricter mobile browsers.
  Future<String> downloadPrepared({
    required BrowserPreparedRecoveryArchive prepared,
    required String suggestedName,
  }) {
    return _runExclusive(() async {
      await _documents.save(
        bytes: prepared.bytes,
        suggestedName: suggestedName,
      );
      return prepared.recoveryCode;
    });
  }

  /// Selects, validates, and atomically restores one archive into an empty profile.
  Future<bool> restore({
    required LocalRebootService destination,
    required String recoveryCode,
  }) {
    return _runExclusive(() async {
      final selected = await _documents.pick();
      if (selected == null) return false;
      await _archives.restore(
        destination: destination,
        archiveBytes: selected.bytes,
        recoveryCode: recoveryCode,
      );
      return true;
    });
  }

  Future<void> copyRecoveryCode(String recoveryCode) {
    return _runExclusive(() => _documents.copySensitive(recoveryCode));
  }

  Future<T> _runExclusive<T>(Future<T> Function() operation) async {
    if (_busy) {
      throw const BrowserRecoveryDocumentException(
        BrowserRecoveryDocumentFailureReason.busy,
      );
    }
    _busy = true;
    try {
      return await operation();
    } finally {
      _busy = false;
    }
  }
}
