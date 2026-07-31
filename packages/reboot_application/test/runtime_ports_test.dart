import 'package:reboot_application/reboot_application.dart';
import 'package:test/test.dart';

void main() {
  test('production identities are distinct RFC 9562 UUID v7 values', () {
    final generator = UuidV7RebootIdentityGenerator();

    final event = generator.nextEventId().value;
    final entity = generator.nextEntityId().value;

    expect(event, isNot(entity));
    expect(event[14], '7');
    expect(entity[14], '7');
    expect('89ab'.contains(event[19]), isTrue);
    expect('89ab'.contains(entity[19]), isTrue);
  });

  test('the production clock always returns UTC', () {
    expect(const SystemRebootClock().nowUtc().isUtc, isTrue);
  });
}
