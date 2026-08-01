import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Honest Web shell displayed before encrypted persistence is validated.
final class WebPrototypeApp extends StatelessWidget {
  const WebPrototypeApp({super.key, this.isStandalone = false});

  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff315c4b)),
        useMaterial3: true,
      ),
      home: _WebPrototypeScreen(isStandalone: isStandalone),
    );
  }
}

final class _WebPrototypeScreen extends StatelessWidget {
  const _WebPrototypeScreen({required this.isStandalone});

  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.enhanced_encryption_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.webPrototypeTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.webPrototypeBody, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.webPrototypeSafety,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WebInstallCard(isStandalone: isStandalone),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _WebInstallCard extends StatelessWidget {
  const _WebInstallCard({required this.isStandalone});

  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isStandalone
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_outlined, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.webInstalledTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.webInstalledBody),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.install_mobile_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.webInstallTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(l10n.webInstallIntro),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.webInstallIosTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.webInstallIosSteps),
                  const SizedBox(height: 12),
                  Text(
                    l10n.webInstallOtherTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.webInstallOtherSteps),
                ],
              ),
      ),
    );
  }
}
