import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../financial_setup/cash_flow_management_screen.dart';
import '../l10n/app_localizations.dart';

/// States what the current Android product actually protects and cannot yet do.
final class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final household = service.configuration.household!;
    final cycleStart = today.isBefore(household.firstCycleStart)
        ? household.firstCycleStart
        : household.cycleContaining(today).start;
    final cashFlows = service.configuration.cashFlowsForCycleStarting(
      cycleStart,
    );
    final fixedCount = cashFlows
        .where((flow) => flow.behavior == AmountBehavior.fixed)
        .length;
    final variableCount = cashFlows.length - fixedCount;
    final confirmations =
        cashFlows
            .map((flow) => flow.lastConfirmedOn)
            .whereType<LocalDate>()
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataPrivacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      l10n.encryptedLocalProfileTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.encryptedLocalProfileBody),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.currentProtectionTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phonelink_lock_outlined),
                    title: Text(l10n.localOnlyDataTitle),
                    subtitle: Text(l10n.localOnlyDataBody),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(l10n.androidBackupDisabledTitle),
                    subtitle: Text(l10n.androidBackupDisabledBody),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: Text(l10n.noTelemetryTitle),
                    subtitle: Text(l10n.noTelemetryBody),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.syncRecoveryTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync_disabled_outlined),
                title: Text(l10n.syncUnavailableTitle),
                subtitle: Text(l10n.syncUnavailableBody),
              ),
            ),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(l10n.recoveryUnavailableTitle),
                subtitle: Text(l10n.recoveryUnavailableBody),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.financialAssumptionsStatusTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.financialAssumptionsCount(cashFlows.length),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.financialAssumptionsKinds(fixedCount, variableCount),
                    ),
                    if (confirmations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.oldestAssumptionConfirmation(
                          _formatDate(context, confirmations.first),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(l10n.assumptionsNeverChangedAutomatically),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('manage-financial-assumptions'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CashFlowManagementScreen(
                            service: service,
                            today: today,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.manageFinancialAssumptions),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, LocalDate date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(
      locale,
    ).format(DateTime(date.year, date.month, date.day));
  }
}
