import 'package:reboot_domain/reboot_domain.dart';
import 'package:uuid/uuid.dart';

/// UTC clock used to make command handling deterministic in tests.
abstract interface class RebootClock {
  /// Returns the current instant in UTC.
  DateTime nowUtc();
}

/// Production clock backed by the operating system.
final class SystemRebootClock implements RebootClock {
  /// Creates the stateless system clock.
  const SystemRebootClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Generates globally stable identities for events and domain entities.
abstract interface class RebootIdentityGenerator {
  /// Returns a fresh UUID for an immutable event.
  EventId nextEventId();

  /// Returns a fresh UUID for a domain entity.
  EntityId nextEntityId();
}

/// Cryptographically strong RFC 9562 UUID v7 generator.
final class UuidV7RebootIdentityGenerator implements RebootIdentityGenerator {
  /// Creates an identity generator using the package's secure RNG.
  UuidV7RebootIdentityGenerator() : _uuid = const Uuid();

  final Uuid _uuid;

  @override
  EventId nextEventId() => EventId(_uuid.v7());

  @override
  EntityId nextEntityId() => EntityId(_uuid.v7());
}
