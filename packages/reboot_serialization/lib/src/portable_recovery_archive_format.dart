import 'dart:convert';
import 'dart:typed_data';

import 'package:reboot_domain/reboot_domain.dart';

import 'event_record_json_codec.dart';

/// Maximum plaintext or encrypted archive accepted by every REBOOT client.
const int portableRecoveryMaximumArchiveBytes = 64 * 1024 * 1024;

/// Maximum number of immutable events accepted in one recovery archive.
const int portableRecoveryMaximumEvents = 1000000;

/// Parsed encrypted envelope whose byte buffers are owned by the caller.
final class PortableRecoveryEnvelope {
  PortableRecoveryEnvelope({
    required Uint8List nonce,
    required Uint8List ciphertext,
  }) : nonce = Uint8List.fromList(nonce),
       ciphertext = Uint8List.fromList(ciphertext);

  final Uint8List nonce;
  final Uint8List ciphertext;
}

/// Platform-neutral `RBP1` archive contract.
///
/// Cryptographic operations deliberately stay outside this codec: Android and
/// browsers use their own AES-256-GCM implementations over these exact bytes.
final class PortableRecoveryArchiveFormat {
  PortableRecoveryArchiveFormat({EventRecordJsonCodec? eventCodec})
    : _eventCodec = eventCodec ?? EventRecordJsonCodec();

  static const int formatVersion = 1;
  static const String algorithm = 'AES-256-GCM';
  static const String recordKind = 'reboot-portable-recovery';
  static const int nonceLength = 12;
  static const int tagLength = 16;
  static const String recoveryCodePrefix = 'RBP1.';
  static const Set<String> _outerFields = <String>{
    'formatVersion',
    'algorithm',
    'recordKind',
    'nonce',
    'ciphertext',
  };
  static const Set<String> _plainFields = <String>{'formatVersion', 'events'};

  final EventRecordJsonCodec _eventCodec;

  /// Serializes a non-empty immutable event stream without numeric loss.
  Uint8List encodePlaintext(Iterable<EventRecord> events) {
    final encodedEvents = <String>[];
    for (final event in events) {
      if (encodedEvents.length >= portableRecoveryMaximumEvents) {
        throw const PortableRecoveryFormatException(
          PortableRecoveryFormatFailureReason.archiveTooLarge,
        );
      }
      encodedEvents.add(_eventCodec.encode(event));
    }
    if (encodedEvents.isEmpty) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveEmpty,
      );
    }
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'formatVersion': formatVersion,
          'events': encodedEvents,
        }),
      ),
    );
    if (bytes.length > portableRecoveryMaximumArchiveBytes) {
      bytes.fillRange(0, bytes.length, 0);
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveTooLarge,
      );
    }
    return bytes;
  }

  /// Parses every event and rejects duplicates before projection validation.
  List<EventRecord> decodePlaintext(Uint8List plaintext) {
    if (plaintext.isEmpty ||
        plaintext.length > portableRecoveryMaximumArchiveBytes) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    final plain = _decodeObject(plaintext, _plainFields);
    if (_requireInt(plain, 'formatVersion') != formatVersion) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    final encodedEvents = plain['events'];
    if (encodedEvents is! List<Object?> ||
        encodedEvents.isEmpty ||
        encodedEvents.length > portableRecoveryMaximumEvents) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    try {
      final events = <EventRecord>[];
      final ids = <EventId>{};
      for (final encoded in encodedEvents) {
        if (encoded is! String) throw const FormatException();
        final event = _eventCodec.decode(encoded);
        if (!ids.add(event.id)) throw const FormatException();
        events.add(event);
      }
      return List<EventRecord>.unmodifiable(events);
    } on Object {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
  }

  /// Wraps AES-GCM output, including its trailing 128-bit tag.
  Uint8List encodeEnvelope({
    required Uint8List nonce,
    required Uint8List ciphertext,
  }) {
    if (nonce.length != nonceLength || ciphertext.length < tagLength) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    final archive = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'formatVersion': formatVersion,
          'algorithm': algorithm,
          'recordKind': recordKind,
          'nonce': _encodeBase64(nonce),
          'ciphertext': _encodeBase64(ciphertext),
        }),
      ),
    );
    if (archive.length > portableRecoveryMaximumArchiveBytes) {
      archive.fillRange(0, archive.length, 0);
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveTooLarge,
      );
    }
    return archive;
  }

  /// Parses and bounds one encrypted archive without decrypting it.
  PortableRecoveryEnvelope decodeEnvelope(Uint8List archiveBytes) {
    if (archiveBytes.isEmpty) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    if (archiveBytes.length > portableRecoveryMaximumArchiveBytes) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveTooLarge,
      );
    }
    final outer = _decodeObject(archiveBytes, _outerFields);
    if (_requireInt(outer, 'formatVersion') != formatVersion ||
        _requireString(outer, 'algorithm') != algorithm ||
        _requireString(outer, 'recordKind') != recordKind) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    final Uint8List nonce;
    final Uint8List ciphertext;
    try {
      nonce = _decodeBase64(_requireString(outer, 'nonce'));
      ciphertext = _decodeBase64(_requireString(outer, 'ciphertext'));
    } on PortableRecoveryFormatException {
      rethrow;
    } on Object {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    if (nonce.length != nonceLength || ciphertext.length < tagLength) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.archiveInvalid,
      );
    }
    return PortableRecoveryEnvelope(nonce: nonce, ciphertext: ciphertext);
  }

  /// Exact additional authenticated data used by every AES-GCM adapter.
  Uint8List authenticatedData() => Uint8List.fromList(
    utf8.encode(
      jsonEncode(<String, Object?>{
        'formatVersion': formatVersion,
        'algorithm': algorithm,
        'recordKind': recordKind,
      }),
    ),
  );

  /// Formats exactly 256 random bits as a separately stored `RBP1` code.
  String encodeRecoveryCode(Uint8List keyBytes) {
    if (keyBytes.length != 32) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.invalidRecoveryCode,
      );
    }
    final encoded = _encodeBase64(keyBytes);
    final groups = <String>[];
    for (var offset = 0; offset < encoded.length; offset += 6) {
      final end = offset + 6 < encoded.length ? offset + 6 : encoded.length;
      groups.add(encoded.substring(offset, end));
    }
    return '$recoveryCodePrefix${groups.join('.')}';
  }

  /// Decodes the exact, case-sensitive recovery code.
  Uint8List decodeRecoveryCode(String value) {
    final compact = value.replaceAll(RegExp(r'\s'), '');
    if (!compact.startsWith(recoveryCodePrefix)) {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.invalidRecoveryCode,
      );
    }
    final encoded = compact
        .substring(recoveryCodePrefix.length)
        .replaceAll('.', '');
    try {
      final bytes = _decodeBase64(encoded);
      if (bytes.length != 32) throw const FormatException();
      return bytes;
    } on Object {
      throw const PortableRecoveryFormatException(
        PortableRecoveryFormatFailureReason.invalidRecoveryCode,
      );
    }
  }
}

enum PortableRecoveryFormatFailureReason {
  invalidRecoveryCode,
  archiveEmpty,
  archiveTooLarge,
  archiveInvalid,
}

final class PortableRecoveryFormatException implements Exception {
  const PortableRecoveryFormatException(this.reason);

  final PortableRecoveryFormatFailureReason reason;
}

Map<String, Object?> _decodeObject(Uint8List bytes, Set<String> fields) {
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
  } on Object {
    throw const PortableRecoveryFormatException(
      PortableRecoveryFormatFailureReason.archiveInvalid,
    );
  }
  if (decoded is! Map<String, Object?> ||
      decoded.keys.length != fields.length ||
      !decoded.keys.toSet().containsAll(fields)) {
    throw const PortableRecoveryFormatException(
      PortableRecoveryFormatFailureReason.archiveInvalid,
    );
  }
  return decoded;
}

String _requireString(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! String) {
    throw const PortableRecoveryFormatException(
      PortableRecoveryFormatFailureReason.archiveInvalid,
    );
  }
  return value;
}

int _requireInt(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! int) {
    throw const PortableRecoveryFormatException(
      PortableRecoveryFormatFailureReason.archiveInvalid,
    );
  }
  return value;
}

String _encodeBase64(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');

Uint8List _decodeBase64(String source) {
  if (source.isEmpty ||
      source.contains('=') ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(source)) {
    throw const FormatException();
  }
  try {
    final decoded = Uint8List.fromList(
      base64Url.decode(base64Url.normalize(source)),
    );
    if (_encodeBase64(decoded) != source) throw const FormatException();
    return decoded;
  } on Object {
    throw const FormatException();
  }
}
