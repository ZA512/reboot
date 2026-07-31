import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/infrastructure/device_context_providers.dart';
import 'package:reboot_domain/reboot_domain.dart';

void main() {
  test('derives the civil date inside the verified device IANA zone', () async {
    final container = ProviderContainer(
      overrides: [
        deviceTimeZoneIdentifierProvider.overrideWith(
          (ref) async => 'America/New_York',
        ),
        currentInstantProvider.overrideWith(
          (ref) => DateTime.utc(2026, 1, 1, 2),
        ),
      ],
    );
    addTearDown(container.dispose);

    final context = await container.read(
      onboardingDeviceContextProvider.future,
    );

    expect(context.localDate, LocalDate(2025, 12, 31));
    expect(context.timeZone, IanaTimeZoneId('America/New_York'));
  });

  test('rejects an identifier absent from the bundled IANA database', () async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        deviceTimeZoneIdentifierProvider.overrideWith(
          (ref) async => 'Mars/Olympus_Mons',
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(onboardingDeviceContextProvider.future),
      throwsA(isA<Exception>()),
    );
  });

  test('canonicalizes the Android GMT alias to Etc/UTC', () async {
    final container = ProviderContainer(
      overrides: [
        currentInstantProvider.overrideWithValue(
          DateTime.utc(2026, 7, 31, 23, 30),
        ),
        deviceTimeZoneIdentifierProvider.overrideWith((ref) async => 'GMT'),
      ],
    );
    addTearDown(container.dispose);

    final context = await container.read(
      onboardingDeviceContextProvider.future,
    );

    expect(context.localDate, LocalDate(2026, 7, 31));
    expect(context.timeZone.value, 'Etc/UTC');
  });
}
