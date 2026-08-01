import 'dart:convert';

import 'encrypted_event_envelope.dart';

const int webPrototypeMaximumProjectionSnapshotBytes = 8 * 1024 * 1024;

/// Decrypted, derived projection state. It is never a source of truth.
final class WebPrototypeProjectionSnapshot {
  WebPrototypeProjectionSnapshot({
    required this.journalPosition,
    required this.schemaVersion,
    required this.projectionJson,
  }) {
    if (journalPosition < BigInt.one || journalPosition > _maximumPosition) {
      throw ArgumentError.value(
        journalPosition,
        'journalPosition',
        'Outside positive signed int64.',
      );
    }
    if (schemaVersion <= 0) {
      throw RangeError.range(schemaVersion, 1, null, 'schemaVersion');
    }
    final bytes = utf8.encode(projectionJson);
    if (bytes.length > webPrototypeMaximumProjectionSnapshotBytes) {
      throw RangeError.range(
        bytes.length,
        0,
        webPrototypeMaximumProjectionSnapshotBytes,
        'projectionJson',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(projectionJson);
    } on FormatException {
      throw const FormatException('The projection snapshot must be JSON.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'The projection snapshot must be a JSON object.',
      );
    }
  }

  static final BigInt _maximumPosition = BigInt.parse('9223372036854775807');

  final BigInt journalPosition;
  final int schemaVersion;
  final String projectionJson;

  List<int> encode() => utf8.encode(
    jsonEncode(<String, Object?>{
      'schemaVersion': schemaVersion,
      'projectionJson': projectionJson,
    }),
  );

  static WebPrototypeProjectionSnapshot decode({
    required BigInt journalPosition,
    required List<int> bytes,
  }) {
    if (bytes.length > webPrototypeMaximumProjectionSnapshotBytes + 4096) {
      throw const FormatException('The projection snapshot is too large.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on Object {
      throw const FormatException('The projection snapshot is invalid.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('The projection snapshot is invalid.');
    }
    return WebPrototypeProjectionSnapshot(
      journalPosition: journalPosition,
      schemaVersion: _requireInt(decoded, 'schemaVersion'),
      projectionJson: _requireString(decoded, 'projectionJson'),
    );
  }
}

/// Persisted AES-GCM envelope for one replaceable projection snapshot.
final class WebEncryptedProjectionSnapshotEnvelope {
  WebEncryptedProjectionSnapshotEnvelope({
    required this.journalPosition,
    required this.journalAnchorBase64Url,
    required this.nonceBase64Url,
    required this.ciphertextBase64Url,
  }) {
    if (journalPosition < BigInt.one || journalPosition > _maximumPosition) {
      throw ArgumentError.value(
        journalPosition,
        'journalPosition',
        'Outside positive signed int64.',
      );
    }
    final anchor = decodeBase64UrlCanonical(
      journalAnchorBase64Url,
      'journalAnchor',
    );
    if (anchor.length != journalAnchorLengthBytes) {
      throw const FormatException('The journal anchor must contain 32 bytes.');
    }
    final nonce = decodeBase64UrlCanonical(nonceBase64Url, 'nonce');
    if (nonce.length != nonceLengthBytes) {
      throw const FormatException('The AES-GCM nonce must contain 12 bytes.');
    }
    final ciphertext = decodeBase64UrlCanonical(
      ciphertextBase64Url,
      'ciphertext',
    );
    if (ciphertext.length < authenticationTagLengthBytes) {
      throw const FormatException('The AES-GCM ciphertext is too short.');
    }
  }

  static const int formatVersion = 1;
  static const String recordKind = 'projection-snapshot';
  static const String algorithm = WebEncryptedEventEnvelope.algorithm;
  static const String keyId = WebEncryptedEventEnvelope.keyId;
  static const int journalAnchorLengthBytes = 32;
  static const int nonceLengthBytes = 12;
  static const int authenticationTagLengthBytes = 16;
  static final BigInt _maximumPosition = BigInt.parse('9223372036854775807');

  final BigInt journalPosition;
  final String journalAnchorBase64Url;
  final String nonceBase64Url;
  final String ciphertextBase64Url;

  List<int> authenticatedData() => utf8.encode(
    jsonEncode(<String, Object?>{
      'formatVersion': formatVersion,
      'recordKind': recordKind,
      'algorithm': algorithm,
      'keyId': keyId,
      'journalPosition': journalPosition.toString(),
      'journalAnchor': journalAnchorBase64Url,
    }),
  );

  Map<String, Object?> toPersistedMap() => <String, Object?>{
    'formatVersion': formatVersion,
    'recordKind': recordKind,
    'algorithm': algorithm,
    'keyId': keyId,
    'journalPosition': journalPosition.toString(),
    'journalAnchor': journalAnchorBase64Url,
    'nonce': nonceBase64Url,
    'ciphertext': ciphertextBase64Url,
  };

  factory WebEncryptedProjectionSnapshotEnvelope.fromPersistedMap(
    Map<String, Object?> map,
  ) {
    if (_requireInt(map, 'formatVersion') != formatVersion ||
        _requireString(map, 'recordKind') != recordKind ||
        _requireString(map, 'algorithm') != algorithm ||
        _requireString(map, 'keyId') != keyId) {
      throw const FormatException('Unsupported projection snapshot format.');
    }
    final positionSource = _requireString(map, 'journalPosition');
    final position = BigInt.tryParse(positionSource);
    if (position == null || position.toString() != positionSource) {
      throw const FormatException('The snapshot position is not canonical.');
    }
    return WebEncryptedProjectionSnapshotEnvelope(
      journalPosition: position,
      journalAnchorBase64Url: _requireString(map, 'journalAnchor'),
      nonceBase64Url: _requireString(map, 'nonce'),
      ciphertextBase64Url: _requireString(map, 'ciphertext'),
    );
  }
}

/// Raised when a cache is written for anything other than the current tail.
final class WebJournalSnapshotPositionException implements Exception {
  const WebJournalSnapshotPositionException();

  @override
  String toString() => 'WebJournalSnapshotPositionException';
}

String _requireString(Map<String, Object?> map, String name) {
  final value = map[name];
  if (value is! String) throw FormatException('$name must be a string.');
  return value;
}

int _requireInt(Map<String, Object?> map, String name) {
  final value = map[name];
  if (value is! int) throw FormatException('$name must be an integer.');
  return value;
}
