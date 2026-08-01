import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/web_storage/encrypted_event_envelope.dart';

void main() {
  test('plain prototype events use one bounded canonical structure', () {
    final event = _event();

    expect(
      WebPrototypePlainEvent.decode(
        eventId: event.eventId,
        bytes: event.encode(),
      ),
      event,
    );
    expect(
      utf8.decode(event.encode()),
      '{"eventType":"expense.recorded","schemaVersion":1,'
      '"payloadJson":"{\\"synthetic\\":true}"}',
    );
  });

  test('rejects malformed identities, JSON, and oversized payloads', () {
    expect(
      () => WebPrototypePlainEvent(
        eventId: 'not-a-uuid',
        eventType: 'expense.recorded',
        schemaVersion: 1,
        payloadJson: '{}',
      ),
      throwsFormatException,
    );
    expect(
      () => WebPrototypePlainEvent(
        eventId: _eventId,
        eventType: 'Expense Recorded',
        schemaVersion: 1,
        payloadJson: '{}',
      ),
      throwsFormatException,
    );
    expect(
      () => WebPrototypePlainEvent(
        eventId: _eventId,
        eventType: 'expense.recorded',
        schemaVersion: 1,
        payloadJson: '{',
      ),
      throwsFormatException,
    );
    expect(
      () => WebPrototypePlainEvent(
        eventId: _eventId,
        eventType: 'expense.recorded',
        schemaVersion: 1,
        payloadJson: jsonEncode('x' * (webPrototypeMaximumPayloadBytes + 1)),
      ),
      throwsRangeError,
    );
  });

  test('envelope authenticates every clear routing field', () {
    final envelope = WebEncryptedEventEnvelope(
      position: BigInt.one,
      eventId: _eventId,
      nonceBase64Url: encodeBase64UrlCanonical(
        List<int>.generate(12, (i) => i),
      ),
      ciphertextBase64Url: encodeBase64UrlCanonical(
        List<int>.generate(32, (i) => i),
      ),
    );

    expect(
      utf8.decode(envelope.authenticatedData()),
      '{"formatVersion":1,"algorithm":"AES-256-GCM",'
      '"keyId":"local-data-key-v1","position":"1",'
      '"eventId":"$_eventId"}',
    );
    expect(
      WebEncryptedEventEnvelope.fromPersistedMap(
        envelope.toPersistedMap(),
      ).toPersistedMap(),
      envelope.toPersistedMap(),
    );
  });

  test('rejects non-canonical or structurally invalid envelopes', () {
    final base = WebEncryptedEventEnvelope(
      position: BigInt.one,
      eventId: _eventId,
      nonceBase64Url: encodeBase64UrlCanonical(List<int>.filled(12, 1)),
      ciphertextBase64Url: encodeBase64UrlCanonical(List<int>.filled(16, 2)),
    ).toPersistedMap();

    expect(
      () => WebEncryptedEventEnvelope.fromPersistedMap(<String, Object?>{
        ...base,
        'position': '01',
      }),
      throwsFormatException,
    );
    expect(
      () => WebEncryptedEventEnvelope.fromPersistedMap(<String, Object?>{
        ...base,
        'nonce': 'AA=',
      }),
      throwsFormatException,
    );
    expect(
      () => WebEncryptedEventEnvelope.fromPersistedMap(<String, Object?>{
        ...base,
        'algorithm': 'AES-CBC',
      }),
      throwsFormatException,
    );
  });
}

WebPrototypePlainEvent _event() => WebPrototypePlainEvent(
  eventId: _eventId,
  eventType: 'expense.recorded',
  schemaVersion: 1,
  payloadJson: '{"synthetic":true}',
);

const String _eventId = '018f1f3a-7b1c-7a2d-8e3f-1234567890ab';
