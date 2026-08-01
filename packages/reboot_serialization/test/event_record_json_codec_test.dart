import 'dart:convert';

import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:test/test.dart';

void main() {
  group('EventRecordJsonCodec', () {
    final codec = EventRecordJsonCodec();

    test('round-trips a complete event canonically', () {
      final event = _event();

      final encoded = codec.encode(event);
      final decoded = codec.decode(encoded);

      expect(codec.encode(decoded), encoded);
      expect(decoded.id, event.id);
      expect(decoded.recordedAtUtc, event.recordedAtUtc);
      expect(decoded.businessDate, event.businessDate);
      expect(decoded.target, event.target);
      expect(encoded, contains('"recordedAtUtcMicros":"'));
      expect(encoded, contains('9007199254740993'));
    });

    test('rejects inconsistent outer metadata', () {
      final value = jsonDecode(codec.encode(_event())) as Map<String, Object?>;

      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...value, 'entityKind': 'reserve'}),
        ),
        throwsFormatException,
      );
      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{
            ...value,
            'eventType': 'expense.deleted',
          }),
        ),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    });

    test('rejects malformed, missing, extra, and non-canonical fields', () {
      final value = jsonDecode(codec.encode(_event())) as Map<String, Object?>;

      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...value, 'eventId': 'not-a-uuid'}),
        ),
        throwsFormatException,
      );
      expect(
        () => codec.decode(
          jsonEncode(Map<String, Object?>.from(value)..remove('businessDate')),
        ),
        throwsFormatException,
      );
      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...value, 'unexpected': true}),
        ),
        throwsFormatException,
      );
      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...value, 'recordedAtUtcMicros': '01'}),
        ),
        throwsFormatException,
      );
      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...value, 'businessDate': '2026-4-04'}),
        ),
        throwsFormatException,
      );
    });
  });
}

EventRecord _event() {
  return EventRecord(
    id: EventId('01960001-1111-7111-8111-111111111111'),
    recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, 0, 123, 456),
    businessDate: LocalDate(2026, 4, 4),
    target: EntityReference(
      kind: EntityKind.expense,
      id: EntityId('01960002-2222-7222-8222-222222222222'),
    ),
    payload: ExpenseRecordedPayload(
      amount: Money.fromMinorUnitsDecimal('9007199254740993', Currency.eur),
      label: 'Courses',
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: LocalDate(2026, 4, 4),
        policyVersion: 1,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
  );
}
