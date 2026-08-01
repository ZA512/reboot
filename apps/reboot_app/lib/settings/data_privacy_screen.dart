import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../financial_setup/cash_flow_management_screen.dart';
import '../l10n/app_localizations.dart';
import 'local_backup_controller.dart';

/// States current protection and creates explicit encrypted recovery backups.
final class DataPrivacyScreen extends ConsumerWidget {
  const DataPrivacyScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final backupOperation = ref.watch(localBackupControllerProvider);
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.backup_outlined),
                      title: Text(l10n.encryptedBackupTitle),
                      subtitle: Text(l10n.encryptedBackupBody),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const ValueKey('create-encrypted-backup'),
                      onPressed: backupOperation.isLoading
                          ? null
                          : () => _export(context, ref),
                      icon: backupOperation.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(
                        backupOperation.isLoading
                            ? l10n.backupCreating
                            : l10n.createEncryptedBackup,
                      ),
                    ),
                    if (backupOperation.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.backupOperationFailed,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
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

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final code = await ref
        .read(localBackupControllerProvider.notifier)
        .export(
          service: service,
          suggestedName: 'reboot-${today.toString()}.reboot-backup',
        );
    if (code == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.backupRecoveryCodeTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.backupRecoveryCodeBody),
              const SizedBox(height: 16),
              Text(l10n.backupRecoveryCodeLabel),
              const SizedBox(height: 6),
              SelectableText(
                code,
                key: const ValueKey('backup-recovery-code'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.backupKeepSeparateWarning),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            key: const ValueKey('copy-recovery-code'),
            onPressed: () async {
              await ref
                  .read(localBackupDocumentPortalProvider)
                  .copySensitive(code);
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.recoveryCodeCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.copyRecoveryCode),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.done),
          ),
        ],
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
