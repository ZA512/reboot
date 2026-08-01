import 'dart:convert';
import 'dart:typed_data';

import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:test/test.dart';

void main() {
  final format = PortableRecoveryArchiveFormat();

  test('round-trips the shared plaintext and encrypted envelope', () {
    final event = _event();
    final plaintext = format.encodePlaintext(<EventRecord>[event]);
    final nonce = Uint8List.fromList(List<int>.generate(12, (index) => index));
    final ciphertext = Uint8List.fromList(
      List<int>.generate(32, (index) => 255 - index),
    );

    final decodedEvents = format.decodePlaintext(plaintext);
    final archive = format.encodeEnvelope(nonce: nonce, ciphertext: ciphertext);
    final envelope = format.decodeEnvelope(archive);

    expect(decodedEvents, hasLength(1));
    expect(decodedEvents.single.id, event.id);
    expect(envelope.nonce, nonce);
    expect(envelope.ciphertext, ciphertext);
    expect(utf8.decode(archive), isNot(contains('Courses')));
  });

  test('uses one exact portable recovery code on every platform', () {
    final key = Uint8List.fromList(List<int>.generate(32, (index) => index));

    final code = format.encodeRecoveryCode(key);

    expect(code, startsWith('RBP1.'));
    expect(format.decodeRecoveryCode('  $code\n'), key);
    expect(
      () => format.decodeRecoveryCode(code.toLowerCase()),
      throwsA(_reason(PortableRecoveryFormatFailureReason.invalidRecoveryCode)),
    );
  });

  test('rejects duplicate events and non-canonical envelopes', () {
    final encodedEvent = EventRecordJsonCodec().encode(_event());
    final duplicatePlaintext = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'formatVersion': 1,
          'events': <String>[encodedEvent, encodedEvent],
        }),
      ),
    );
    final archive = format.encodeEnvelope(
      nonce: Uint8List(12),
      ciphertext: Uint8List(16),
    );
    final outer = jsonDecode(utf8.decode(archive)) as Map<String, Object?>;

    expect(
      () => format.decodePlaintext(duplicatePlaintext),
      throwsA(_reason(PortableRecoveryFormatFailureReason.archiveInvalid)),
    );
    expect(
      () => format.decodeEnvelope(
        Uint8List.fromList(
          utf8.encode(jsonEncode(<String, Object?>{...outer, 'extra': true})),
        ),
      ),
      throwsA(_reason(PortableRecoveryFormatFailureReason.archiveInvalid)),
    );
    expect(
      () => format.decodeEnvelope(
        Uint8List.fromList(
          utf8.encode(jsonEncode(<String, Object?>{...outer, 'nonce': 'AA=='})),
        ),
      ),
      throwsA(_reason(PortableRecoveryFormatFailureReason.archiveInvalid)),
    );
  });
}

TypeMatcher<PortableRecoveryFormatException> _reason(
  PortableRecoveryFormatFailureReason reason,
) => isA<PortableRecoveryFormatException>().having(
  (error) => error.reason,
  'reason',
  reason,
);

EventRecord _event() {
  return EventRecord(
    id: EventId('01960001-1111-7111-8111-111111111111'),
    recordedAtUtc: DateTime.utc(2026, 4, 1, 10),
    businessDate: LocalDate(2026, 4, 4),
    target: EntityReference(
      kind: EntityKind.expense,
      id: EntityId('01960002-2222-7222-8222-222222222222'),
    ),
    payload: ExpenseRecordedPayload(
      amount: Money.fromMinorUnits(4200, Currency.eur),
      label: 'Courses',
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: LocalDate(2026, 4, 4),
        policyVersion: 1,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
  );
}
