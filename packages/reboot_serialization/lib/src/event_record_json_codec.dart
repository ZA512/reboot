import 'dart:convert';

import 'package:reboot_domain/reboot_domain.dart';

import 'event_payload_json_codec.dart';

/// Cross-platform canonical JSON codec for one complete immutable event.
///
/// Integers whose exact value matters across JavaScript and native runtimes are
/// represented as canonical decimal strings.
final class EventRecordJsonCodec {
  /// Creates a complete event codec using the current payload codec.
  EventRecordJsonCodec({EventPayloadJsonCodec? payloadCodec})
    : _payloadCodec = payloadCodec ?? EventPayloadJsonCodec();

  static const Set<String> _fields = <String>{
    'eventId',
    'recordedAtUtcMicros',
    'businessDate',
    'entityKind',
    'entityId',
    'eventType',
    'schemaVersion',
    'payloadJson',
  };

  final EventPayloadJsonCodec _payloadCodec;

  /// Encodes [event] without any platform-dependent numeric conversion.
  String encode(EventRecord event) {
    return jsonEncode(<String, Object?>{
      'eventId': event.id.value,
      'recordedAtUtcMicros': event.recordedAtUtc.microsecondsSinceEpoch
          .toString(),
      'businessDate': event.businessDate.toString(),
      'entityKind': event.target.kind.name,
      'entityId': event.target.id.value,
      'eventType': event.eventType,
      'schemaVersion': event.schemaVersion,
      'payloadJson': _payloadCodec.encode(event.payload),
    });
  }

  /// Decodes a complete event and rejects non-canonical or inconsistent data.
  EventRecord decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on Object {
      throw const FormatException('The stored event JSON is invalid.');
    }
    if (decoded is! Map<String, Object?> ||
        decoded.keys.toSet().length != _fields.length ||
        !decoded.keys.toSet().containsAll(_fields)) {
      throw const FormatException('The stored event fields are invalid.');
    }

    final eventType = _string(decoded, 'eventType');
    final schemaVersion = _int(decoded, 'schemaVersion');
    final payloadJson = _string(decoded, 'payloadJson');
    final payload = _payloadCodec.decode(
      eventType: eventType,
      schemaVersion: schemaVersion,
      json: payloadJson,
    );
    if (payload.eventType != eventType ||
        payload.schemaVersion != schemaVersion ||
        _payloadCodec.encode(payload) != payloadJson) {
      throw const FormatException('The stored event payload is inconsistent.');
    }

    final microsSource = _string(decoded, 'recordedAtUtcMicros');
    final micros = int.tryParse(microsSource);
    if (micros == null || micros.toString() != microsSource) {
      throw const FormatException(
        'The stored event timestamp is not canonical.',
      );
    }

    final kind = _entityKind(_string(decoded, 'entityKind'));
    if (kind != payload.targetKind) {
      throw const FormatException('The stored event target is inconsistent.');
    }
    return EventRecord(
      id: EventId(_string(decoded, 'eventId')),
      recordedAtUtc: DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true),
      businessDate: _date(_string(decoded, 'businessDate')),
      target: EntityReference(
        kind: kind,
        id: EntityId(_string(decoded, 'entityId')),
      ),
      payload: payload,
    );
  }
}

String _string(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! String) {
    throw FormatException('The stored event field $field must be a string.');
  }
  return value;
}

int _int(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! int) {
    throw FormatException('The stored event field $field must be an integer.');
  }
  return value;
}

EntityKind _entityKind(String name) {
  for (final kind in EntityKind.values) {
    if (kind.name == name) return kind;
  }
  throw FormatException('Unsupported stored entity kind: $name');
}

LocalDate _date(String source) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(source);
  if (match == null) {
    throw const FormatException('The stored business date is invalid.');
  }
  try {
    final date = LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (date.toString() != source) {
      throw const FormatException('The stored business date is not canonical.');
    }
    return date;
  } on FormatException {
    rethrow;
  } on Object {
    throw const FormatException('The stored business date is invalid.');
  }
}
