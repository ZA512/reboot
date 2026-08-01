import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:web/web.dart' as web;

import 'encrypted_event_envelope.dart';

/// Maximum encrypted Web recovery archive accepted by REBOOT.
const int browserRecoveryMaximumArchiveBytes = 64 * 1024 * 1024;

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
  BrowserRecoveryArchiveService({EventRecordJsonCodec? eventCodec})
    : _eventCodec = eventCodec ?? EventRecordJsonCodec();

  static const int _formatVersion = 1;
  static const String _algorithm = 'AES-256-GCM';
  static const String _recordKind = 'reboot-portable-recovery';
  static const int _nonceLength = 12;
  static const int _tagLength = 16;
  static const int _maximumEvents = 1000000;
  static const Set<String> _outerFields = <String>{
    'formatVersion',
    'algorithm',
    'recordKind',
    'nonce',
    'ciphertext',
  };
  static const Set<String> _plainFields = <String>{'formatVersion', 'events'};

  final EventRecordJsonCodec _eventCodec;

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
    if (entries.length > _maximumEvents) {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveTooLarge,
      );
    }
    final plaintext = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'formatVersion': _formatVersion,
          'events': <String>[
            for (final entry in entries) _eventCodec.encode(entry.event),
          ],
        }),
      ),
    );
    if (plaintext.length > browserRecoveryMaximumArchiveBytes) {
      plaintext.fillRange(0, plaintext.length, 0);
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveTooLarge,
      );
    }

    try {
      final keyBytes = _randomBytes(32);
      final recoveryCode = _encodeRecoveryCode(keyBytes);
      final web.CryptoKey key;
      try {
        key = await _importKey(keyBytes);
      } finally {
        keyBytes.fillRange(0, keyBytes.length, 0);
      }
      final nonce = _randomBytes(_nonceLength);
      final encrypted = await web.window.crypto.subtle
          .encrypt(_aesParameters(nonce), key, plaintext.toJS)
          .toDart;
      final archive = Uint8List.fromList(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'formatVersion': _formatVersion,
            'algorithm': _algorithm,
            'recordKind': _recordKind,
            'nonce': encodeBase64UrlCanonical(nonce),
            'ciphertext': encodeBase64UrlCanonical(
              _arrayBufferBytes(encrypted),
            ),
          }),
        ),
      );
      if (archive.length > browserRecoveryMaximumArchiveBytes) {
        archive.fillRange(0, archive.length, 0);
        throw const BrowserRecoveryArchiveException(
          BrowserRecoveryArchiveFailureReason.archiveTooLarge,
        );
      }
      return BrowserPreparedRecoveryArchive(
        bytes: archive,
        recoveryCode: recoveryCode,
      );
    } on BrowserRecoveryArchiveException {
      rethrow;
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
    if (archiveBytes.isEmpty) {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveInvalid,
      );
    }
    if (archiveBytes.length > browserRecoveryMaximumArchiveBytes) {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveTooLarge,
      );
    }
    final outer = _decodeObject(archiveBytes, _outerFields);
    if (_requireInt(outer, 'formatVersion') != _formatVersion ||
        _requireString(outer, 'algorithm') != _algorithm ||
        _requireString(outer, 'recordKind') != _recordKind) {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveInvalid,
      );
    }
    final nonce = _decodeBase64(_requireString(outer, 'nonce'));
    final ciphertext = _decodeBase64(_requireString(outer, 'ciphertext'));
    if (nonce.length != _nonceLength || ciphertext.length < _tagLength) {
      throw const BrowserRecoveryArchiveException(
        BrowserRecoveryArchiveFailureReason.archiveInvalid,
      );
    }

    final keyBytes = _decodeRecoveryCode(recoveryCode);
    final web.CryptoKey key;
    try {
      key = await _importKey(keyBytes);
    } finally {
      keyBytes.fillRange(0, keyBytes.length, 0);
    }
    final Uint8List plaintext;
    try {
      final decrypted = await web.window.crypto.subtle
          .decrypt(_aesParameters(nonce), key, ciphertext.toJS)
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
      final plain = _decodeObject(plaintext, _plainFields);
      if (_requireInt(plain, 'formatVersion') != _formatVersion) {
        throw const FormatException();
      }
      final encodedEvents = plain['events'];
      if (encodedEvents is! List<Object?> ||
          encodedEvents.isEmpty ||
          encodedEvents.length > _maximumEvents) {
        throw const FormatException();
      }
      final events = <EventRecord>[];
      final ids = <EventId>{};
      for (final encoded in encodedEvents) {
        if (encoded is! String) throw const FormatException();
        final event = _eventCodec.decode(encoded);
        if (!ids.add(event.id)) throw const FormatException();
        events.add(event);
      }
      journal = _ArchiveJournal(events);
      validation = await LocalRebootService.restore(journal: journal);
      journal = null;
      if (validation.configuration.household == null) {
        throw const FormatException();
      }
      return await validation.readJournalSnapshot();
    } on BrowserRecoveryArchiveException {
      rethrow;
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

  static JSAny _aesParameters(Uint8List nonce) {
    return <String, Object?>{
      'name': 'AES-GCM',
      'iv': nonce,
      'additionalData': Uint8List.fromList(_authenticatedData()),
      'tagLength': 128,
    }.jsify()!;
  }

  static List<int> _authenticatedData() => utf8.encode(
    jsonEncode(<String, Object?>{
      'formatVersion': _formatVersion,
      'algorithm': _algorithm,
      'recordKind': _recordKind,
    }),
  );
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

Uint8List _randomBytes(int length) {
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

String _encodeRecoveryCode(Uint8List keyBytes) {
  final encoded = encodeBase64UrlCanonical(keyBytes);
  final groups = <String>[];
  for (var offset = 0; offset < encoded.length; offset += 6) {
    final end = offset + 6 < encoded.length ? offset + 6 : encoded.length;
    groups.add(encoded.substring(offset, end));
  }
  return 'RBP1.${groups.join('.')}';
}

Uint8List _decodeRecoveryCode(String value) {
  final compact = value.replaceAll(RegExp(r'\s'), '');
  if (!compact.startsWith('RBP1.')) {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.invalidRecoveryCode,
    );
  }
  final encoded = compact.substring(5).replaceAll('.', '');
  try {
    final bytes = Uint8List.fromList(
      decodeBase64UrlCanonical(encoded, 'recoveryCode'),
    );
    if (bytes.length != 32) throw const FormatException();
    return bytes;
  } on Object {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.invalidRecoveryCode,
    );
  }
}

Map<String, Object?> _decodeObject(Uint8List bytes, Set<String> fields) {
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
  } on Object {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.archiveInvalid,
    );
  }
  if (decoded is! Map<String, Object?> ||
      decoded.keys.length != fields.length ||
      !decoded.keys.toSet().containsAll(fields)) {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.archiveInvalid,
    );
  }
  return decoded;
}

String _requireString(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! String) {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.archiveInvalid,
    );
  }
  return value;
}

int _requireInt(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! int) {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.archiveInvalid,
    );
  }
  return value;
}

Uint8List _decodeBase64(String source) {
  try {
    return Uint8List.fromList(decodeBase64UrlCanonical(source, 'archive'));
  } on Object {
    throw const BrowserRecoveryArchiveException(
      BrowserRecoveryArchiveFailureReason.archiveInvalid,
    );
  }
}

List<int> _arrayBufferBytes(JSAny? value) {
  final buffer = value as JSArrayBuffer;
  return Uint8List.view(buffer.toDart);
}
