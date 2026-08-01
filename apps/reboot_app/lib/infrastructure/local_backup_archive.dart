import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:reboot_storage/reboot_storage.dart';

import 'local_profile_bootstrap.dart';

/// One temporary encrypted archive and the separately displayed recovery code.
final class PreparedLocalBackup {
  const PreparedLocalBackup({required this.file, required this.recoveryCode});

  final File file;
  final String recoveryCode;
}

/// Creates and validates versioned recovery codes for local backup keys.
abstract final class LocalBackupRecoveryCode {
  static const String _prefix = 'RB1.';

  /// Formats exactly 256 random bits without retaining another key copy.
  static String encode(Uint8List keyBytes) {
    if (keyBytes.length != 32) {
      throw const LocalBackupException(
        LocalBackupFailureReason.invalidRecoveryCode,
      );
    }
    final encoded = base64UrlEncode(keyBytes).replaceAll('=', '');
    final groups = <String>[];
    for (var offset = 0; offset < encoded.length; offset += 6) {
      final end = offset + 6 < encoded.length ? offset + 6 : encoded.length;
      groups.add(encoded.substring(offset, end));
    }
    return '$_prefix${groups.join('.')}';
  }

  /// Decodes the exact, case-sensitive code and rejects every other format.
  static Uint8List decode(String value) {
    final compact = value.replaceAll(RegExp(r'\s'), '');
    if (!compact.startsWith(_prefix)) {
      throw const LocalBackupException(
        LocalBackupFailureReason.invalidRecoveryCode,
      );
    }
    final encoded = compact.substring(_prefix.length).replaceAll('.', '');
    if (encoded.length != 43 ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(encoded)) {
      throw const LocalBackupException(
        LocalBackupFailureReason.invalidRecoveryCode,
      );
    }
    try {
      final decoded = Uint8List.fromList(base64Url.decode('$encoded='));
      if (decoded.length != 32) {
        throw const FormatException();
      }
      return decoded;
    } on Object {
      throw const LocalBackupException(
        LocalBackupFailureReason.invalidRecoveryCode,
      );
    }
  }
}

/// Native encrypted recovery archive boundary.
abstract interface class LocalBackupArchive {
  Future<PreparedLocalBackup> prepare(LocalRebootService service);

  Future<void> restore({
    required LocalRebootService destination,
    required File file,
    required String recoveryCode,
  });

  Future<void> discard(PreparedLocalBackup backup);
}

/// Portable AES-GCM archive with backward-compatible `RB1` restoration.
final class LocalBackupArchiveService implements LocalBackupArchive {
  LocalBackupArchiveService({
    required this.temporaryDirectory,
    required this.keyGenerator,
    required this.openJournal,
    this.maxArchiveBytes = portableRecoveryMaximumArchiveBytes,
    Uint8List Function(int length)? randomBytes,
    PortableRecoveryArchiveFormat? portableFormat,
  }) : randomBytes = randomBytes ?? _secureRandomBytes,
       _portableFormat = portableFormat ?? PortableRecoveryArchiveFormat();

  final Future<Directory> Function() temporaryDirectory;
  final DatabaseKeyMaterialGenerator keyGenerator;

  /// Retained solely to restore SQLite-based Android archives created before
  /// the portable `RBP1` format was introduced.
  final LocalJournalOpener openJournal;
  final int maxArchiveBytes;
  final Uint8List Function(int length) randomBytes;
  final PortableRecoveryArchiveFormat _portableFormat;

  static final AesGcm _cipher = AesGcm.with256bits();

  /// Encrypts the current immutable journal into the cross-platform format.
  @override
  Future<PreparedLocalBackup> prepare(LocalRebootService service) async {
    final snapshot = await service.readJournalSnapshot();
    if (snapshot.isEmpty) {
      throw const LocalBackupException(LocalBackupFailureReason.archiveEmpty);
    }
    final Directory directory;
    try {
      directory = await temporaryDirectory();
      await directory.create(recursive: true);
    } on Object {
      throw const LocalBackupException(
        LocalBackupFailureReason.temporaryStorageUnavailable,
      );
    }
    final file = File(
      path.join(
        directory.absolute.path,
        'reboot-backup-${DateTime.now().toUtc().microsecondsSinceEpoch}.reboot-backup',
      ),
    );
    final Uint8List plaintext;
    try {
      plaintext = _portableFormat.encodePlaintext(
        snapshot.map((entry) => entry.event),
      );
    } on PortableRecoveryFormatException catch (error) {
      throw _localException(error);
    }
    SecretKeyData? key;
    var completed = false;
    try {
      final keyBytes = keyGenerator.generate();
      if (keyBytes.length != 32) {
        keyBytes.fillRange(0, keyBytes.length, 0);
        throw const LocalBackupException(
          LocalBackupFailureReason.temporaryKeyUnavailable,
        );
      }
      final String recoveryCode;
      try {
        recoveryCode = _portableFormat.encodeRecoveryCode(keyBytes);
        key = SecretKeyData(
          Uint8List.fromList(keyBytes),
          overwriteWhenDestroyed: true,
        );
      } finally {
        keyBytes.fillRange(0, keyBytes.length, 0);
      }
      final nonce = randomBytes(PortableRecoveryArchiveFormat.nonceLength);
      if (nonce.length != PortableRecoveryArchiveFormat.nonceLength) {
        nonce.fillRange(0, nonce.length, 0);
        throw const LocalBackupException(
          LocalBackupFailureReason.temporaryKeyUnavailable,
        );
      }
      final secretBox = await _cipher.encrypt(
        plaintext,
        secretKey: key,
        nonce: nonce,
        aad: _portableFormat.authenticatedData(),
      );
      final ciphertext = Uint8List.fromList(<int>[
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);
      final archiveBytes = _portableFormat.encodeEnvelope(
        nonce: nonce,
        ciphertext: ciphertext,
      );
      ciphertext.fillRange(0, ciphertext.length, 0);
      await file.writeAsBytes(archiveBytes, flush: true);
      archiveBytes.fillRange(0, archiveBytes.length, 0);
      final length = await file.length();
      if (length <= 0 || length > maxArchiveBytes) {
        throw const LocalBackupException(
          LocalBackupFailureReason.archiveTooLarge,
        );
      }
      completed = true;
      return PreparedLocalBackup(file: file, recoveryCode: recoveryCode);
    } on LocalBackupException {
      rethrow;
    } on PortableRecoveryFormatException catch (error) {
      throw _localException(error);
    } on Object {
      throw const LocalBackupException(
        LocalBackupFailureReason.archiveCreationFailed,
      );
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
      key?.destroy();
      if (!completed && file.existsSync()) {
        await file.delete();
      }
    }
  }

  /// Authenticates and fully replays a portable or legacy Android archive.
  Future<List<LocalJournalEntry>> read({
    required File file,
    required String recoveryCode,
  }) async {
    final int length;
    try {
      length = await file.length();
    } on Object {
      throw const LocalBackupException(
        LocalBackupFailureReason.archiveUnavailable,
      );
    }
    if (length <= 0 || length > maxArchiveBytes) {
      throw const LocalBackupException(
        LocalBackupFailureReason.archiveTooLarge,
      );
    }
    if (recoveryCode
        .replaceAll(RegExp(r'\s'), '')
        .startsWith(PortableRecoveryArchiveFormat.recoveryCodePrefix)) {
      final Uint8List archiveBytes;
      try {
        archiveBytes = await file.readAsBytes();
      } on Object {
        throw const LocalBackupException(
          LocalBackupFailureReason.archiveUnavailable,
        );
      }
      return _readPortable(
        archiveBytes: archiveBytes,
        recoveryCode: recoveryCode,
      );
    }
    return _readLegacy(file: file, recoveryCode: recoveryCode);
  }

  Future<List<LocalJournalEntry>> _readPortable({
    required Uint8List archiveBytes,
    required String recoveryCode,
  }) async {
    final PortableRecoveryEnvelope envelope;
    final Uint8List keyBytes;
    try {
      envelope = _portableFormat.decodeEnvelope(archiveBytes);
      keyBytes = _portableFormat.decodeRecoveryCode(recoveryCode);
    } on PortableRecoveryFormatException catch (error) {
      throw _localException(error);
    }
    final key = SecretKeyData(
      Uint8List.fromList(keyBytes),
      overwriteWhenDestroyed: true,
    );
    keyBytes.fillRange(0, keyBytes.length, 0);
    final tagOffset =
        envelope.ciphertext.length - PortableRecoveryArchiveFormat.tagLength;
    final box = SecretBox(
      envelope.ciphertext.sublist(0, tagOffset),
      nonce: envelope.nonce,
      mac: Mac(envelope.ciphertext.sublist(tagOffset)),
    );
    final Uint8List plaintext;
    try {
      plaintext = Uint8List.fromList(
        await _cipher.decrypt(
          box,
          secretKey: key,
          aad: _portableFormat.authenticatedData(),
        ),
      );
    } on Object {
      throw const LocalBackupException(LocalBackupFailureReason.archiveInvalid);
    } finally {
      key.destroy();
    }

    _ArchiveJournal? journal;
    LocalRebootService? validationService;
    try {
      final events = _portableFormat.decodePlaintext(plaintext);
      journal = _ArchiveJournal(events);
      validationService = await LocalRebootService.restore(journal: journal);
      journal = null;
      final snapshot = await validationService.readJournalSnapshot();
      if (snapshot.isEmpty ||
          validationService.configuration.household == null) {
        throw const LocalBackupException(
          LocalBackupFailureReason.archiveInvalid,
        );
      }
      return snapshot;
    } on LocalBackupException {
      rethrow;
    } on PortableRecoveryFormatException catch (error) {
      throw _localException(error);
    } on Object {
      throw const LocalBackupException(LocalBackupFailureReason.archiveInvalid);
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
      archiveBytes.fillRange(0, archiveBytes.length, 0);
      if (validationService != null) {
        await validationService.close();
      } else if (journal != null) {
        await journal.close();
      }
    }
  }

  Future<List<LocalJournalEntry>> _readLegacy({
    required File file,
    required String recoveryCode,
  }) async {
    final keyBytes = LocalBackupRecoveryCode.decode(recoveryCode);
    final key = EncryptedDatabaseKey(keyBytes);
    keyBytes.fillRange(0, keyBytes.length, 0);
    LocalEventJournal? journal;
    LocalRebootService? validationService;
    try {
      journal = await openJournal(file.absolute.path, key);
      validationService = await LocalRebootService.restore(journal: journal);
      journal = null;
      final snapshot = await validationService.readJournalSnapshot();
      if (snapshot.isEmpty ||
          validationService.configuration.household == null) {
        throw const LocalBackupException(
          LocalBackupFailureReason.archiveInvalid,
        );
      }
      return snapshot;
    } on LocalBackupException {
      rethrow;
    } on Object {
      throw const LocalBackupException(LocalBackupFailureReason.archiveInvalid);
    } finally {
      key.destroy();
      if (validationService != null) {
        await validationService.close();
      } else if (journal != null) {
        await journal.close();
      }
    }
  }

  /// Imports only after the complete archive has passed cryptographic and
  /// projection validation.
  @override
  Future<void> restore({
    required LocalRebootService destination,
    required File file,
    required String recoveryCode,
  }) async {
    final snapshot = await read(file: file, recoveryCode: recoveryCode);
    try {
      await destination.restoreJournalSnapshot(snapshot);
    } on JournalSnapshotImportException {
      throw const LocalBackupException(
        LocalBackupFailureReason.localProfileNotEmpty,
      );
    }
  }

  /// Deletes an app-private temporary archive after the system has copied it.
  @override
  Future<void> discard(PreparedLocalBackup backup) async {
    try {
      if (await backup.file.exists()) await backup.file.delete();
      final wal = File('${backup.file.path}-wal');
      if (await wal.exists()) await wal.delete();
      final shm = File('${backup.file.path}-shm');
      if (await shm.exists()) await shm.delete();
    } on Object {
      // The private cache is non-authoritative and is also reclaimed by the OS.
    }
  }
}

final class _ArchiveJournal implements LocalEventJournal {
  _ArchiveJournal(List<EventRecord> events)
    : _entries = List<LocalJournalEntry>.unmodifiable(<LocalJournalEntry>[
        for (var index = 0; index < events.length; index += 1)
          LocalJournalEntry(
            position: LocalJournalPosition(index + 1),
            event: events[index],
          ),
      ]);

  final List<LocalJournalEntry> _entries;
  bool _closed = false;

  @override
  Future<List<LocalJournalEntry>> readAll() async {
    if (_closed) throw StateError('Archive journal is closed.');
    return _entries;
  }

  @override
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events) {
    throw UnsupportedError('Archive validation journal is read-only.');
  }

  @override
  Future<void> close() async => _closed = true;
}

Uint8List _secureRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256)),
  );
}

LocalBackupException _localException(PortableRecoveryFormatException error) {
  return LocalBackupException(switch (error.reason) {
    PortableRecoveryFormatFailureReason.invalidRecoveryCode =>
      LocalBackupFailureReason.invalidRecoveryCode,
    PortableRecoveryFormatFailureReason.archiveEmpty =>
      LocalBackupFailureReason.archiveEmpty,
    PortableRecoveryFormatFailureReason.archiveTooLarge =>
      LocalBackupFailureReason.archiveTooLarge,
    PortableRecoveryFormatFailureReason.archiveInvalid =>
      LocalBackupFailureReason.archiveInvalid,
  });
}

/// Sanitized local backup error with no file path or financial content.
final class LocalBackupException implements Exception {
  const LocalBackupException(this.reason);

  final LocalBackupFailureReason reason;
}

enum LocalBackupFailureReason {
  invalidRecoveryCode,
  archiveEmpty,
  archiveTooLarge,
  archiveUnavailable,
  archiveInvalid,
  archiveCreationFailed,
  temporaryStorageUnavailable,
  temporaryKeyUnavailable,
  localProfileNotEmpty,
}
