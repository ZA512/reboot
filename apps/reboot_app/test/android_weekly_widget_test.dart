import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/infrastructure/android_weekly_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.za512.reboot/weekly_widget');
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'requestPinWeeklyWidget';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'publishes only display state and its exclusive validity date',
    () async {
      await AndroidWeeklyWidget.update(
        displayAmount: '147,00',
        validBeforeDate: '2026-04-11',
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'updateWeeklyWidget');
      expect(calls.single.arguments, {
        'displayAmount': '147,00',
        'validBeforeDate': '2026-04-11',
      });
    },
  );

  test(
    'uses the native launcher pin flow without another dependency',
    () async {
      expect(await AndroidWeeklyWidget.requestPin(), isTrue);
      expect(calls.single.method, 'requestPinWeeklyWidget');
    },
  );
}
