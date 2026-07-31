import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

/// One auditable local date and IANA zone captured from the same instant.
final class OnboardingDeviceContext {
  /// Creates a verified device context.
  const OnboardingDeviceContext({
    required this.localDate,
    required this.timeZone,
  });

  /// Civil date visible in the detected device zone.
  final LocalDate localDate;

  /// Verified IANA identifier persisted with the initial cycle policy.
  final IanaTimeZoneId timeZone;
}

/// Replaceable UTC clock used only to derive onboarding device context.
final currentInstantProvider = Provider<DateTime>(
  (ref) => DateTime.now().toUtc(),
);

/// Small owned platform boundary for the operating-system IANA identifier.
final deviceTimeZoneIdentifierProvider = FutureProvider<String>((ref) async {
  const channel = MethodChannel('com.za512.reboot/device_context');
  final identifier = await channel.invokeMethod<String>(
    'getLocalTimeZoneIdentifier',
  );
  if (identifier == null || identifier.trim().isEmpty) {
    throw StateError('The platform returned no time-zone identifier.');
  }
  return identifier;
});

/// Detects and verifies the device's IANA zone before onboarding can finish.
final onboardingDeviceContextProvider = FutureProvider<OnboardingDeviceContext>(
  (ref) async {
    final platformIdentifier = await ref.watch(
      deviceTimeZoneIdentifierProvider.future,
    );
    final identifier = _canonicalIanaIdentifier(platformIdentifier);
    time_zone_data.initializeTimeZones();
    final location = time_zone.getLocation(identifier);
    final localInstant = time_zone.TZDateTime.from(
      ref.watch(currentInstantProvider),
      location,
    );
    return OnboardingDeviceContext(
      localDate: LocalDate.fromDateTime(localInstant),
      timeZone: IanaTimeZoneId(location.name),
    );
  },
);

String _canonicalIanaIdentifier(String platformIdentifier) {
  // Android may expose these standard zero-offset IANA links as the short
  // identifier "GMT". The compact timezone database intentionally omits some
  // links, so persist its canonical equivalent instead.
  return switch (platformIdentifier.trim()) {
    'GMT' || 'UTC' || 'UCT' || 'Universal' || 'Zulu' => 'Etc/UTC',
    final identifier => identifier,
  };
}
