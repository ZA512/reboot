import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';

import '../infrastructure/profile_providers.dart';

/// Root material application after platform bindings and providers exist.
final class RebootApp extends StatelessWidget {
  /// Creates the root application.
  const RebootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REBOOT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff315c4b)),
        useMaterial3: true,
      ),
      home: const ProfileStartupGate(),
    );
  }
}

/// Distinguishes startup, locked profile, onboarding, and ready states.
final class ProfileStartupGate extends ConsumerWidget {
  /// Creates the startup gate.
  const ProfileStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(localRebootServiceProvider);
    return profile.when(
      loading: () => const _LoadingScreen(),
      error: (error, stackTrace) => _LockedProfileScreen(
        onRetry: () => ref.invalidate(localRebootServiceProvider),
      ),
      data: (service) {
        if (service.configuration.household == null) {
          return const _OnboardingWelcomeScreen();
        }
        return _ReadyScreen(service: service);
      },
    );
  }
}

final class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Ouverture du profil REBOOT',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

final class _LockedProfileScreen extends StatelessWidget {
  const _LockedProfileScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REBOOT')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Le profil local ne peut pas être ouvert.',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aucune donnée n’a été supprimée ni recréée. '
                  'Déverrouillez l’appareil puis réessayez.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _OnboardingWelcomeScreen extends StatelessWidget {
  const _OnboardingWelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REBOOT')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reprenez vos dépenses en main, une semaine à la fois.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  'REBOOT transforme vos revenus, charges et objectifs en '
                  'un montant hebdomadaire simple à suivre.',
                ),
                const SizedBox(height: 24),
                const Text('Votre profil local chiffré est prêt.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ReadyScreen extends StatelessWidget {
  const _ReadyScreen({required this.service});

  final LocalRebootService service;

  @override
  Widget build(BuildContext context) {
    final household = service.configuration.household!;
    return Scaffold(
      appBar: AppBar(title: const Text('REBOOT')),
      body: Center(
        child: Text(
          'Profil ${household.householdKind.name} prêt',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
