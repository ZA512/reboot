import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';

/// Deliberately blocks real Web data until the encrypted journal prototype
/// proves its persistence, key custody, recovery, and erasure behavior.
final localRebootServiceProvider = FutureProvider<LocalRebootService>((ref) {
  throw const WebProfilePrototypeUnavailableException();
});

/// Non-sensitive marker used only to select the honest pre-prototype UI.
final class WebProfilePrototypeUnavailableException implements Exception {
  const WebProfilePrototypeUnavailableException();
}
