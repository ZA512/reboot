import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/device_context_providers.dart';
import '../infrastructure/profile_providers.dart';
import '../l10n/app_localizations.dart';
import '../settings/local_backup_controller.dart';
import 'onboarding_controller.dart';

/// Two-stage introduction and initial weekly-cycle configuration.
final class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the first-run experience.
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isConfiguring = false;
  HouseholdKind _householdKind = HouseholdKind.sharedMainAccount;
  Weekday _anchorWeekday = Weekday.saturday;
  FirstCycleStartChoice _firstCycleChoice = FirstCycleStartChoice.nextAnchor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        leading: _isConfiguring
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => setState(() => _isConfiguring = false),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _isConfiguring
                  ? _buildConfiguration(context)
                  : _buildWelcome(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final backupOperation = ref.watch(localBackupControllerProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_view_week_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.welcomeHeadline,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(l10n.welcomeBody, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.encryptedProfileReady)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _isConfiguring = true),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.startSetup),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('restore-encrypted-backup'),
              onPressed: backupOperation.isLoading
                  ? null
                  : () => _restoreBackup(context),
              icon: backupOperation.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text(
                backupOperation.isLoading
                    ? l10n.backupRestoring
                    : l10n.restoreEncryptedBackup,
              ),
            ),
          ),
          if (backupOperation.hasError) ...[
            const SizedBox(height: 12),
            Text(
              l10n.backupRestoreFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final recoveryCode = await showDialog<String>(
      context: context,
      builder: (_) => const _RecoveryCodeDialog(),
    );
    if (recoveryCode == null || !mounted) return;
    final service = await ref.read(localRebootServiceProvider.future);
    await ref
        .read(localBackupControllerProvider.notifier)
        .restore(service: service, recoveryCode: recoveryCode);
  }

  Widget _buildConfiguration(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deviceContext = ref.watch(onboardingDeviceContextProvider);
    final submission = ref.watch(onboardingControllerProvider);
    final detectedContext = switch (deviceContext) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final today = detectedContext?.localDate;
    final nextStart = today?.weekdayOnOrAfter(_anchorWeekday);
    final previousStart = today?.weekdayOnOrBefore(_anchorWeekday);
    final startsToday = nextStart != null && nextStart == previousStart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.setupTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l10n.setupIntro),
        const SizedBox(height: 28),
        _Section(
          title: l10n.householdQuestion,
          child: Column(
            children: [
              _ChoiceCard<HouseholdKind>(
                value: HouseholdKind.sharedMainAccount,
                groupValue: _householdKind,
                title: l10n.sharedHouseholdTitle,
                subtitle: l10n.sharedHouseholdBody,
                icon: Icons.people_outline,
                onSelected: _selectHousehold,
              ),
              const SizedBox(height: 8),
              _ChoiceCard<HouseholdKind>(
                value: HouseholdKind.solo,
                groupValue: _householdKind,
                title: l10n.soloHouseholdTitle,
                subtitle: l10n.soloHouseholdBody,
                icon: Icons.person_outline,
                onSelected: _selectHousehold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: l10n.rebootDayQuestion,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<Weekday>(
                initialValue: _anchorWeekday,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event_repeat),
                  labelText: l10n.rebootDayQuestion,
                ),
                items: [
                  for (final weekday in Weekday.values)
                    DropdownMenuItem(
                      value: weekday,
                      child: Text(_weekdayLabel(l10n, weekday)),
                    ),
                ],
                onChanged: submission.isLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _anchorWeekday = value;
                          if (today?.weekday == value) {
                            _firstCycleChoice =
                                FirstCycleStartChoice.nextAnchor;
                          }
                        });
                      },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.rebootDayHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: l10n.startQuestion,
          child: _buildStartChoice(
            context,
            deviceContext: deviceContext,
            nextStart: nextStart,
            previousStart: previousStart,
            startsToday: startsToday,
            disabled: submission.isLoading,
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: l10n.timeZoneTitle,
          child: _buildTimeZone(context, deviceContext),
        ),
        if (submission.hasError) ...[
          const SizedBox(height: 20),
          _ErrorNotice(message: l10n.setupError),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: detectedContext == null || submission.isLoading
                ? null
                : () => ref
                      .read(onboardingControllerProvider.notifier)
                      .submit(
                        OnboardingDraft(
                          householdKind: _householdKind,
                          onboardingDate: detectedContext.localDate,
                          anchorWeekday: _anchorWeekday,
                          timeZone: detectedContext.timeZone,
                          firstCycleChoice: _firstCycleChoice,
                        ),
                      ),
            child: submission.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.creatingProfile),
                    ],
                  )
                : Text(l10n.confirmSetup),
          ),
        ),
      ],
    );
  }

  Widget _buildStartChoice(
    BuildContext context, {
    required AsyncValue<OnboardingDeviceContext> deviceContext,
    required LocalDate? nextStart,
    required LocalDate? previousStart,
    required bool startsToday,
    required bool disabled,
  }) {
    final l10n = AppLocalizations.of(context);
    return deviceContext.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorNotice(message: l10n.timeZoneError),
      data: (value) {
        if (startsToday) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.today),
            title: Text(l10n.startsToday),
          );
        }
        return Column(
          children: [
            _ChoiceCard<FirstCycleStartChoice>(
              value: FirstCycleStartChoice.nextAnchor,
              groupValue: _firstCycleChoice,
              title: l10n.startNextTitle(_formatDate(context, nextStart!)),
              subtitle: l10n.startNextBody,
              icon: Icons.arrow_forward,
              onSelected: disabled ? null : _selectFirstCycle,
            ),
            const SizedBox(height: 8),
            _ChoiceCard<FirstCycleStartChoice>(
              value: FirstCycleStartChoice.previousAnchorWithExpenseCatchUp,
              groupValue: _firstCycleChoice,
              title: l10n.startPreviousTitle(
                _formatDate(context, previousStart!),
              ),
              subtitle: l10n.startPreviousBody,
              icon: Icons.history,
              onSelected: disabled ? null : _selectFirstCycle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeZone(
    BuildContext context,
    AsyncValue<OnboardingDeviceContext> deviceContext,
  ) {
    final l10n = AppLocalizations.of(context);
    return deviceContext.when(
      loading: () => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircularProgressIndicator(),
        title: Text(l10n.timeZoneLoading),
      ),
      error: (error, stackTrace) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ErrorNotice(message: l10n.timeZoneError),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(onboardingDeviceContextProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.detectAgain),
          ),
        ],
      ),
      data: (value) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.public),
        title: Text(l10n.timeZoneDetected(value.timeZone.value)),
      ),
    );
  }

  void _selectHousehold(HouseholdKind value) {
    setState(() => _householdKind = value);
  }

  void _selectFirstCycle(FirstCycleStartChoice value) {
    setState(() => _firstCycleChoice = value);
  }
}

final class _RecoveryCodeDialog extends StatefulWidget {
  const _RecoveryCodeDialog();

  @override
  State<_RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

final class _RecoveryCodeDialogState extends State<_RecoveryCodeDialog> {
  final _key = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.restoreEncryptedBackup),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreBackupIntro),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('restore-recovery-code'),
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.backupRecoveryCodeLabel,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.requiredField
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('select-backup-file'),
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            Navigator.pop(context, _controller.text.trim());
          },
          child: Text(l10n.selectBackupFile),
        ),
      ],
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

final class _ChoiceCard<T> extends StatelessWidget {
  const _ChoiceCard({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
  });

  final T value;
  final T groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Card(
        elevation: 0,
        color: selected ? colors.secondaryContainer : colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected == null ? null : () => onSelected!(value),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(selected ? Icons.check_circle : Icons.circle_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colors.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, LocalDate date) {
  return MaterialLocalizations.of(
    context,
  ).formatFullDate(DateTime(date.year, date.month, date.day));
}

String _weekdayLabel(AppLocalizations l10n, Weekday weekday) {
  return switch (weekday) {
    Weekday.monday => l10n.weekdayMonday,
    Weekday.tuesday => l10n.weekdayTuesday,
    Weekday.wednesday => l10n.weekdayWednesday,
    Weekday.thursday => l10n.weekdayThursday,
    Weekday.friday => l10n.weekdayFriday,
    Weekday.saturday => l10n.weekdaySaturday,
    Weekday.sunday => l10n.weekdaySunday,
  };
}
