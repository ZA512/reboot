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
    expect(find.text('Installer l’app Web REBOOT'), findsOneWidget);
    expect(find.text('Sur iPhone dans Safari'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(2));
    for (var index = 0; index < 2; index += 1) {
      final card = tester.getRect(cards.at(index));
      expect(card.left, greaterThanOrEqualTo(24));
      expect(card.right, lessThanOrEqualTo(366));
    }
  });

  testWidgets('confirms standalone mode without repeating install steps', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const WebPrototypeApp(isStandalone: true));
    await tester.pumpAndSettle();

    expect(find.text('REBOOT is open as an installed web app'), findsOneWidget);
    expect(find.text('On iPhone in Safari'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
}
