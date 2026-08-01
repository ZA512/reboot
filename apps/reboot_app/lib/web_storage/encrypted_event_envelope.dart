import 'dart:convert';

/// Maximum clear payload accepted by the storage prototype.
const int webPrototypeMaximumPayloadBytes = 1024 * 1024;

/// Synthetic event used only to prove the encrypted Web journal.
///
/// The real application remains disconnected from this prototype until the
/// complete Web storage decision is accepted.
final class WebPrototypePlainEvent {
  WebPrototypePlainEvent({
    required this.eventId,
    required this.eventType,
    required this.schemaVersion,
    required this.payloadJson,
  }) {
    if (!_uuidPattern.hasMatch(eventId)) {
      throw FormatException('The prototype event ID must be a canonical UUID.');
    }
    if (!_eventTypePattern.hasMatch(eventType)) {
      throw FormatException('The prototype event type is invalid.');
    }
    if (schemaVersion <= 0) {
      throw RangeError.range(schemaVersion, 1, null, 'schemaVersion');
    }
    final payloadBytes = utf8.encode(payloadJson);
    if (payloadBytes.length > webPrototypeMaximumPayloadBytes) {
      throw RangeError.range(
        payloadBytes.length,
        0,
        webPrototypeMaximumPayloadBytes,
        'payloadJson',
      );
    }
    try {
      jsonDecode(payloadJson);
    } on FormatException {
      throw const FormatException('The prototype payload must be valid JSON.');
    }
  }

  final String eventId;
  final String eventType;
  final int schemaVersion;
  final String payloadJson;

  List<int> encode() => utf8.encode(
    jsonEncode(<String, Object?>{
      'eventType': eventType,
      'schemaVersion': schemaVersion,
      'payloadJson': payloadJson,
    }),
  );

  static WebPrototypePlainEvent decode({
    required String eventId,
    required List<int> bytes,
  }) {
    if (bytes.length > webPrototypeMaximumPayloadBytes + 4096) {
      throw const FormatException(
        'The decrypted prototype event is too large.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on Object {
      throw const FormatException('The decrypted prototype event is invalid.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('The decrypted prototype event is invalid.');
    }
    return WebPrototypePlainEvent(
      eventId: eventId,
      eventType: _requireString(decoded, 'eventType'),
      schemaVersion: _requireInt(decoded, 'schemaVersion'),
      payloadJson: _requireString(decoded, 'payloadJson'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WebPrototypePlainEvent &&
      eventId == other.eventId &&
      eventType == other.eventType &&
      schemaVersion == other.schemaVersion &&
      payloadJson == other.payloadJson;

  @override
  int get hashCode =>
      Object.hash(eventId, eventType, schemaVersion, payloadJson);
}

/// Persisted authenticated envelope. Only the ciphertext contains event data.
final class WebEncryptedEventEnvelope {
  WebEncryptedEventEnvelope({
    required this.position,
    required this.eventId,
    required this.nonceBase64Url,
    required this.ciphertextBase64Url,
  }) {
    if (position < BigInt.one || position > _maximumPosition) {
      throw ArgumentError.value(position, 'position', 'Outside signed int64.');
    }
    if (!_uuidPattern.hasMatch(eventId)) {
      throw FormatException('The encrypted event ID must be a canonical UUID.');
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
  static const String algorithm = 'AES-256-GCM';
  static const String keyId = 'local-data-key-v1';
  static const int nonceLengthBytes = 12;
  static const int authenticationTagLengthBytes = 16;
  static final BigInt _maximumPosition = BigInt.parse('9223372036854775807');

  final BigInt position;
  final String eventId;
  final String nonceBase64Url;
  final String ciphertextBase64Url;

  String get positionKey => position.toString().padLeft(19, '0');

  List<int> authenticatedData() => utf8.encode(
    jsonEncode(<String, Object?>{
      'formatVersion': formatVersion,
      'algorithm': algorithm,
      'keyId': keyId,
      'position': position.toString(),
      'eventId': eventId,
    }),
  );

  Map<String, Object?> toPersistedMap() => <String, Object?>{
    'formatVersion': formatVersion,
    'algorithm': algorithm,
    'keyId': keyId,
    'position': position.toString(),
    'eventId': eventId,
    'nonce': nonceBase64Url,
    'ciphertext': ciphertextBase64Url,
  };

  factory WebEncryptedEventEnvelope.fromPersistedMap(Map<String, Object?> map) {
    if (_requireInt(map, 'formatVersion') != formatVersion ||
        _requireString(map, 'algorithm') != algorithm ||
        _requireString(map, 'keyId') != keyId) {
      throw const FormatException('Unsupported encrypted envelope format.');
    }
    final positionSource = _requireString(map, 'position');
    final position = BigInt.tryParse(positionSource);
    if (position == null || position.toString() != positionSource) {
      throw const FormatException('The encrypted position is not canonical.');
    }
    return WebEncryptedEventEnvelope(
      position: position,
      eventId: _requireString(map, 'eventId'),
      nonceBase64Url: _requireString(map, 'nonce'),
      ciphertextBase64Url: _requireString(map, 'ciphertext'),
    );
  }
}

/// Sanitized failure raised when authentication or stored structure fails.
final class WebJournalIntegrityException implements Exception {
  const WebJournalIntegrityException();

  @override
  String toString() => 'WebJournalIntegrityException';
}

/// Raised when browser state proves that a local key or database was lost.
final class WebJournalKeyUnavailableException implements Exception {
  const WebJournalKeyUnavailableException();

  @override
  String toString() => 'WebJournalKeyUnavailableException';
}

/// Raised when one event UUID is reused for different immutable content.
final class WebJournalEventConflictException implements Exception {
  const WebJournalEventConflictException();

  @override
  String toString() => 'WebJournalEventConflictException';
}

/// Sanitized browser persistence failure that carries no stored content.
final class WebJournalStorageException implements Exception {
  const WebJournalStorageException();

  @override
  String toString() => 'WebJournalStorageException';
}

String encodeBase64UrlCanonical(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

List<int> decodeBase64UrlCanonical(String source, String field) {
  if (source.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(source)) {
    throw FormatException('$field is not canonical base64url.');
  }
  final padding = '=' * ((4 - source.length % 4) % 4);
  final List<int> decoded;
  try {
    decoded = base64Url.decode('$source$padding');
  } on FormatException {
    throw FormatException('$field is not canonical base64url.');
  }
  if (encodeBase64UrlCanonical(decoded) != source) {
    throw FormatException('$field is not canonical base64url.');
  }
  return decoded;
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

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-'
  r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final RegExp _eventTypePattern = RegExp(r'^[a-z][a-z0-9.-]{0,99}$');
