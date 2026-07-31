import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../l10n/app_localizations.dart';
import 'cycle_settings_controller.dart';

/// Lets the household schedule a new weekly anchor without rewriting history.
final class CycleSettingsScreen extends ConsumerStatefulWidget {
  const CycleSettingsScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  ConsumerState<CycleSettingsScreen> createState() =>
      _CycleSettingsScreenState();
}

final class _CycleSettingsScreenState
    extends ConsumerState<CycleSettingsScreen> {
  late Weekday _selectedWeekday;

  @override
  void initState() {
    super.initState();
    _selectedWeekday =
        widget.service.configuration.household!.latestCyclePolicy.anchorWeekday;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(cycleSettingsControllerProvider);
    final household = widget.service.configuration.household!;
    final latest = household.latestCyclePolicy;
    final active = widget.today.isBefore(household.firstCycleStart)
        ? household.cyclePolicies.first
        : household.cycleContaining(widget.today).policy;
    final scheduled =
        latest.version > active.version &&
        widget.today.isBefore(latest.firstNormalCycleStart);
    final effectiveFrom = scheduled
        ? latest.effectiveFrom
        : widget.service.nextConfigurationCycleStart(widget.today);
    final changed = _selectedWeekday != latest.anchorWeekday;
    final preview = changed && !scheduled
        ? CycleCalendar.changeAnchor(
            previousPolicy: latest,
            nextPolicy: CyclePolicy(
              version: latest.version + 1,
              effectiveFrom: effectiveFrom,
              anchorWeekday: _selectedWeekday,
              timeZone: latest.timeZone,
            ),
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cycleSettingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(l10n.cycleSettingsIntro),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_repeat),
                title: Text(l10n.currentRebootDay),
                subtitle: Text(_weekdayLabel(l10n, active.anchorWeekday)),
              ),
            ),
            const SizedBox(height: 16),
            if (scheduled)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(
                    l10n.rebootDayAlreadyScheduled(
                      _weekdayLabel(l10n, latest.anchorWeekday),
                      _formatDate(context, latest.firstNormalCycleStart),
                    ),
                  ),
                  subtitle: Text(l10n.rebootDayScheduledLocked),
                ),
              )
            else ...[
              DropdownButtonFormField<Weekday>(
                key: const ValueKey('new-reboot-day'),
                initialValue: _selectedWeekday,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.newRebootDay,
                ),
                items: [
                  for (final weekday in Weekday.values)
                    DropdownMenuItem(
                      value: weekday,
                      child: Text(_weekdayLabel(l10n, weekday)),
                    ),
                ],
                onChanged: mutation.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedWeekday = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              Text(l10n.rebootDayChangeHelp),
              if (preview != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rebootDayChangePreview(
                            _weekdayLabel(l10n, _selectedWeekday),
                            _formatDate(
                              context,
                              preview.firstNormalCycle.start,
                            ),
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.rebootTransitionPreview(
                            _formatDate(context, preview.transition.start),
                            _formatDate(
                              context,
                              preview.transition.endInclusive,
                            ),
                            preview.transition.dateCount,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.rebootTransitionTrendHelp),
                      ],
                    ),
                  ),
                ),
              ],
              if (mutation.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.rebootDayChangeError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('save-reboot-day'),
                onPressed: !changed || mutation.isLoading
                    ? null
                    : () => _save(effectiveFrom, latest.timeZone),
                icon: mutation.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_available_outlined),
                label: Text(l10n.scheduleRebootDayChange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(LocalDate effectiveFrom, IanaTimeZoneId timeZone) async {
    final accepted = await ref
        .read(cycleSettingsControllerProvider.notifier)
        .submit(
          anchorWeekday: _selectedWeekday,
          timeZone: timeZone,
          effectiveFrom: effectiveFrom,
          businessDate: widget.today,
        );
    if (accepted && mounted) Navigator.of(context).pop(true);
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
