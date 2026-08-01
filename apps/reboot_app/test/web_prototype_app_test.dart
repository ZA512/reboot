import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/src/web_prototype_app.dart';

void main() {
  testWidgets('keeps the blocked Web shell readable on an iPhone viewport', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const WebPrototypeApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Le stockage Web sécurisé est en cours de validation'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);

    final card = tester.getRect(find.byType(Card));
    expect(card.left, greaterThanOrEqualTo(24));
    expect(card.right, lessThanOrEqualTo(366));
  });
}
