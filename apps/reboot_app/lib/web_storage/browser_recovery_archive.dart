import 'dart:js_interop';
import 'dart:typed_data';

import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:web/web.dart' as web;

/// Maximum encrypted Web recovery archive accepted by REBOOT.
const int browserRecoveryMaximumArchiveBytes =
    portableRecoveryMaximumArchiveBytes;

/// Encrypted bytes to download and the key that must be kept separately.
final class BrowserPreparedRecoveryArchive {
  BrowserPreparedRecoveryArchive({
    required Uint8List bytes,
    required this.recoveryCode,
  }) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
  final String recoveryCode;
}

/// Creates and restores browser-native encrypted journal archives.
///
/// The archive is independent from the non-extractable local data key. Its
/// separately displayed recovery code contains a fresh 256-bit export key.
final class BrowserRecoveryArchiveService {
  BrowserRecoveryArchiveService({
    EventRecordJsonCodec? eventCodec,
    Uint8List Function(int length)? randomBytes,
  }) : _format = PortableRecoveryArchiveFormat(eventCodec: eventCodec),
       _randomBytes = randomBytes ?? _secureBrowserRandomBytes;

  final PortableRecoveryArchiveFormat _format;
  final Uint8List Function(int length) _randomBytes;

  /// Encrypts one consistent journal snapshot with a fresh recovery key.
  Future<BrowserPreparedRecoveryArchive> prepare(
    LocalRebootService service,
  ) async {
    final entries = await service.readJournalSnapshot();
    if (entries.isEmpty) {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveEmpty,
      );
    }
    final Uint8List plaintext;
    try {
      plaintext = _format.encodePlaintext(entries.map((entry) => entry.event));
    } on PortableRecoveryFormatException catch (error) {
      throw _archiveException(error);
    }

    try {
      final keyBytes = _randomBytes(32);
      final recoveryCode = _format.encodeRecoveryCode(keyBytes);
      final web.CryptoKey key;
      try {
        key = await _importKey(keyBytes);
      } finally {
        keyBytes.fillRange(0, keyBytes.length, 0);
      }
      final nonce = _randomBytes(PortableRecoveryArchiveFormat.nonceLength);
      final encrypted = await web.window.crypto.subtle
          .encrypt(_aesParameters(nonce, _format), key, plaintext.toJS)
          .toDart;
      final archive = _format.encodeEnvelope(
        nonce: nonce,
        ciphertext: Uint8List.fromList(_arrayBufferBytes(encrypted)),
      );
      return BrowserPreparedRecoveryArchive(
        bytes: archive,
        recoveryCode: recoveryCode,
      );
    } on BrowserRecoveryArchiveException {
      rethrow;
    } on PortableRecoveryFormatException catch (error) {
      throw _archiveException(error);
    } on Object {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveCreationFailed,
      );
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
    }
  }

  /// Authenticates and replays the entire archive before modifying [destination].
  Future<void> restore({
    required LocalRebootService destination,
    required Uint8List archiveBytes,
    required String recoveryCode,
  }) async {
    final snapshot = await _read(archiveBytes, recoveryCode);
    try {
      await destination.restoreJournalSnapshot(snapshot);
    } on JournalSnapshotImportException {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.localProfileNotEmpty,
      );
    }
  }

  Future<List<LocalJournalEntry>> _read(
    Uint8List archiveBytes,
    String recoveryCode,
  ) async {
    final PortableRecoveryEnvelope envelope;
    try {
      envelope = _format.decodeEnvelope(archiveBytes);
    } on PortableRecoveryFormatException catch (error) {
      throw _archiveException(error);
    }
    final Uint8List keyBytes;
    try {
      keyBytes = _format.decodeRecoveryCode(recoveryCode);
    } on PortableRecoveryFormatException catch (error) {
      throw _archiveException(error);
    }
    final web.CryptoKey key;
    try {
      key = await _importKey(keyBytes);
    } finally {
      keyBytes.fillRange(0, keyBytes.length, 0);
    }
    final Uint8List plaintext;
    try {
      final decrypted = await web.window.crypto.subtle
          .decrypt(
            _aesParameters(envelope.nonce, _format),
            key,
            envelope.ciphertext.toJS,
          )
          .toDart;
      plaintext = Uint8List.fromList(_arrayBufferBytes(decrypted));
    } on Object {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveInvalid,
      );
    }

    _ArchiveJournal? journal;
    LocalRebootService? validation;
    try {
      final events = _format.decodePlaintext(plaintext);
      journal = _ArchiveJournal(events);
      validation = await LocalRebootService.restore(journal: journal);
      journal = null;
      if (validation.configuration.household == null) {
        throw const FormatException();
      }
      return await validation.readJournalSnapshot();
    } on BrowserRecoveryArchiveException {
      rethrow;
    } on PortableRecoveryFormatException catch (error) {
      throw _archiveException(error);
    } on Object {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveInvalid,
      );
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
      if (validation != null) {
        await validation.close();
      } else if (journal != null) {
        await journal.close();
      }
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

/// Sanitized recovery failure that contains no financial or cryptographic data.
final class BrowserRecoveryArchiveException implements Exception {
  const BrowserRecoveryArchiveException(this.reason);

  final BrowserRecoveryArchiveFailureReason reason;
}

enum BrowserRecoveryArchiveFailureReason {
  invalidRecoveryCode,
  archiveEmpty,
  archiveTooLarge,
  archiveInvalid,
  archiveCreationFailed,
  cryptographyUnavailable,
  localProfileNotEmpty,
}

Future<web.CryptoKey> _importKey(Uint8List keyBytes) async {
  try {
    final imported = await web.window.crypto.subtle
        .importKey(
          'raw',
          keyBytes.toJS,
          <String, Object?>{'name': 'AES-GCM'}.jsify()!,
          false,
          <JSString>['encrypt'.toJS, 'decrypt'.toJS].toJS,
        )
        .toDart;
    return imported;
  } on Object {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.cryptographyUnavailable,
    );
  }
}

Uint8List _secureBrowserRandomBytes(int length) {
  final bytes = Uint8List(length);
  try {
    web.window.crypto.getRandomValues(bytes.toJS);
    return bytes;
  } on Object {
    bytes.fillRange(0, bytes.length, 0);
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.cryptographyUnavailable,
    );
  }
}

List<int> _arrayBufferBytes(JSAny? value) {
  final buffer = value as JSArrayBuffer;
  return Uint8List.view(buffer.toDart);
}

JSAny _aesParameters(Uint8List nonce, PortableRecoveryArchiveFormat format) {
  return <String, Object?>{
    'name': 'AES-GCM',
    'iv': nonce,
    'additionalData': format.authenticatedData(),
    'tagLength': 128,
  }.jsify()!;
}

BrowserRecoveryArchiveException _archiveException(
  PortableRecoveryFormatException error,
) {
  return BrowserRecoveryArchiveException(switch (error.reason) {
    PortableRecoveryFormatFailureReason.invalidRecoveryCode =>
      BrowserRecoveryArchiveFailureReason.invalidRecoveryCode,
    PortableRecoveryFormatFailureReason.archiveEmpty =>
      BrowserRecoveryArchiveFailureReason.archiveEmpty,
    PortableRecoveryFormatFailureReason.archiveTooLarge =>
      BrowserRecoveryArchiveFailureReason.archiveTooLarge,
    PortableRecoveryFormatFailureReason.archiveInvalid =>
      BrowserRecoveryArchiveFailureReason.archiveInvalid,
  });
}
