import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/web_storage/encrypted_event_envelope.dart';
import 'package:reboot_app/web_storage/encrypted_projection_snapshot.dart';

void main() {
  test('projection snapshot uses one bounded JSON object', () {
    final snapshot = WebPrototypeProjectionSnapshot(
      journalPosition: BigInt.from(42),
      schemaVersion: 3,
      projectionJson: '{"remainingMinorUnits":"12345"}',
    );

    final decoded = WebPrototypeProjectionSnapshot.decode(
      journalPosition: snapshot.journalPosition,
      bytes: snapshot.encode(),
    );
    expect(decoded.journalPosition, snapshot.journalPosition);
    expect(decoded.schemaVersion, snapshot.schemaVersion);
    expect(decoded.projectionJson, snapshot.projectionJson);
    expect(
      () => WebPrototypeProjectionSnapshot(
        journalPosition: BigInt.one,
        schemaVersion: 1,
        projectionJson: '[]',
      ),
      throwsFormatException,
    );
  });

  test('encrypted snapshot authenticates its journal anchor and routing', () {
    final anchor = encodeBase64UrlCanonical(List<int>.generate(32, (i) => i));
    final envelope = WebEncryptedProjectionSnapshotEnvelope(
      journalPosition: BigInt.from(42),
      journalAnchorBase64Url: anchor,
      nonceBase64Url: encodeBase64UrlCanonical(List<int>.filled(12, 7)),
      ciphertextBase64Url: encodeBase64UrlCanonical(List<int>.filled(16, 9)),
    );

    expect(
      utf8.decode(envelope.authenticatedData()),
      jsonEncode(<String, Object?>{
        'formatVersion': 1,
        'recordKind': 'projection-snapshot',
        'algorithm': 'AES-256-GCM',
        'keyId': 'local-data-key-v1',
        'journalPosition': '42',
        'journalAnchor': anchor,
      }),
    );
    final decoded = WebEncryptedProjectionSnapshotEnvelope.fromPersistedMap(
      envelope.toPersistedMap(),
    );
    expect(decoded.journalPosition, BigInt.from(42));
    expect(decoded.journalAnchorBase64Url, anchor);
  });
}
