import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Narrow platform boundary for REBOOT's privacy-preserving Android widget.
final class AndroidWeeklyWidget {
  AndroidWeeklyWidget._();

  static const MethodChannel _channel = MethodChannel(
    'com.za512.reboot/weekly_widget',
  );

  /// Whether this build can expose the native Android widget integration.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Stores only the already-formatted remaining amount and its validity date.
  static Future<void> update({
    required String displayAmount,
    required String validBeforeDate,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('updateWeeklyWidget', {
        'displayAmount': displayAmount,
        'validBeforeDate': validBeforeDate,
      });
    } on MissingPluginException {
      // Widget tests and non-Android embedders intentionally have no host side.
    } on PlatformException {
      // The dashboard must remain usable if the optional widget cannot update.
    }
  }

  /// Opens the launcher's standard confirmation UI when supported.
  static Future<bool> requestPin() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPinWeeklyWidget') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
