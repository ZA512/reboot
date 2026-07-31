import 'package:reboot_domain/reboot_domain.dart';

import 'projection_errors.dart';

enum HealthEntryKind { expense, reimbursement, regularization }

/// One aggregate or individual health entry and any later correction.
final class ProjectedHealthEntry {
  const ProjectedHealthEntry._({
    required this.eventId,
    required this.kind,
    required this.amount,
    required this.label,
    required this.businessDate,
    required this.recordedAtUtc,
    this.reversalEventId,
  });

  final EventId eventId;
  final HealthEntryKind kind;
  final Money amount;
  final String label;
  final LocalDate businessDate;
  final DateTime recordedAtUtc;
  final EventId? reversalEventId;

  bool get isReversed => reversalEventId != null;

  ProjectedHealthEntry _reversedBy(EventRecord event) => ProjectedHealthEntry._(
    eventId: eventId,
    kind: kind,
    amount: amount,
    label: label,
    businessDate: businessDate,
    recordedAtUtc: recordedAtUtc,
    reversalEventId: event.id,
  );
}

/// Current optional health-tracking configuration and aggregate journal.
final class ProjectedHealthTracking {
  ProjectedHealthTracking._({
    required this.id,
    required this.enabled,
    required this.delayWeeks,
    required this.alertThreshold,
    required this.trackingStartDate,
    required List<ProjectedHealthEntry> entries,
    required this.latestConfigurationEventId,
  }) : entries = List<ProjectedHealthEntry>.unmodifiable(entries);

  final EntityId id;
  final bool enabled;
  final int delayWeeks;
  final Money alertThreshold;
  final LocalDate? trackingStartDate;
  final List<ProjectedHealthEntry> entries;
  final EventId latestConfigurationEventId;

  Iterable<ProjectedHealthEntry> get activeEntries =>
      entries.where((entry) => !entry.isReversed);

  /// Aggregate estimate at [asOfDate], never interpreted as a bank balance.
  Money estimatedRest(LocalDate asOfDate) {
    final start = trackingStartDate;
    if (!enabled || start == null) return Money.zero(Currency.eur);
    var expenses = Money.zero(Currency.eur);
    var reimbursements = Money.zero(Currency.eur);
    var regularizations = Money.zero(Currency.eur);
    for (final entry in activeEntries) {
      if (entry.businessDate.isBefore(start) ||
          entry.businessDate.isAfter(asOfDate)) {
        continue;
      }
      switch (entry.kind) {
        case HealthEntryKind.expense:
          final maturity = entry.businessDate.addDays(delayWeeks * 7);
          if (!maturity.isAfter(asOfDate)) expenses = expenses + entry.amount;
        case HealthEntryKind.reimbursement:
          reimbursements = reimbursements + entry.amount;
        case HealthEntryKind.regularization:
          regularizations = regularizations + entry.amount;
      }
    }
    return expenses - reimbursements - regularizations;
  }

  bool requiresAttention(LocalDate asOfDate) =>
      estimatedRest(asOfDate).compareTo(alertThreshold) > 0;

  ProjectedHealthTracking _reconfigured(EventRecord event) {
    final payload = event.payload as HealthTrackingConfiguredPayload;
    final startsNewEpoch = payload.enabled && !enabled;
    return ProjectedHealthTracking._(
      id: id,
      enabled: payload.enabled,
      delayWeeks: payload.delayWeeks,
      alertThreshold: payload.alertThreshold,
      trackingStartDate: startsNewEpoch
          ? event.businessDate
          : trackingStartDate,
      entries: entries,
      latestConfigurationEventId: event.id,
    );
  }

  ProjectedHealthTracking _withEntry(ProjectedHealthEntry entry) =>
      ProjectedHealthTracking._(
        id: id,
        enabled: enabled,
        delayWeeks: delayWeeks,
        alertThreshold: alertThreshold,
        trackingStartDate: trackingStartDate,
        entries: [...entries, entry],
        latestConfigurationEventId: latestConfigurationEventId,
      );

  ProjectedHealthTracking _reverseEntry(EventRecord event, EventId entryId) {
    final index = entries.indexWhere((entry) => entry.eventId == entryId);
    if (index < 0) {
      throw ProjectionConflictException(
        'Health tracking $id does not contain entry $entryId.',
      );
    }
    if (entries[index].isReversed) {
      throw ProjectionConflictException(
        'Health entry $entryId received multiple reversals.',
      );
    }
    final next = List<ProjectedHealthEntry>.of(entries);
    next[index] = next[index]._reversedBy(event);
    return ProjectedHealthTracking._(
      id: id,
      enabled: enabled,
      delayWeeks: delayWeeks,
      alertThreshold: alertThreshold,
      trackingStartDate: trackingStartDate,
      entries: next,
      latestConfigurationEventId: latestConfigurationEventId,
    );
  }
}

/// Pure replay projection for optional aggregate health tracking.
final class HealthLedger {
  HealthLedger._({
    required this.tracking,
    required Set<EventId> appliedEventIds,
    required this.lastPosition,
  }) : _appliedEventIds = Set<EventId>.unmodifiable(appliedEventIds);

  factory HealthLedger.empty() => HealthLedger._(
    tracking: null,
    appliedEventIds: const {},
    lastPosition: null,
  );

  factory HealthLedger.replay(Iterable<LocalJournalEntry> entries) => entries
      .fold(HealthLedger.empty(), (ledger, entry) => ledger.apply(entry));

  final ProjectedHealthTracking? tracking;
  final Set<EventId> _appliedEventIds;
  final LocalJournalPosition? lastPosition;

  HealthLedger apply(LocalJournalEntry entry) {
    if (_appliedEventIds.contains(entry.event.id)) return this;
    if (lastPosition != null && entry.position.compareTo(lastPosition!) <= 0) {
      throw LocalJournalOrderException(
        previous: lastPosition!,
        received: entry.position,
      );
    }
    var next = tracking;
    if (entry.event.target.kind == EntityKind.healthTracking) {
      switch (entry.event.payload) {
        case HealthTrackingConfiguredPayload(
          :final enabled,
          :final delayWeeks,
          :final alertThreshold,
        ):
          if (next == null) {
            next = ProjectedHealthTracking._(
              id: entry.event.target.id,
              enabled: enabled,
              delayWeeks: delayWeeks,
              alertThreshold: alertThreshold,
              trackingStartDate: enabled ? entry.event.businessDate : null,
              entries: const [],
              latestConfigurationEventId: entry.event.id,
            );
          } else {
            if (next.id != entry.event.target.id) {
              throw const ProjectionConflictException(
                'The journal contains multiple health trackers.',
              );
            }
            next = next._reconfigured(entry.event);
          }
        case HealthExpenseRecordedPayload(:final amount, :final label):
          next = _requireEnabled(next)._withEntry(
            _entry(entry.event, HealthEntryKind.expense, amount, label),
          );
        case HealthReimbursementRecordedPayload(:final amount, :final label):
          next = _requireEnabled(next)._withEntry(
            _entry(entry.event, HealthEntryKind.reimbursement, amount, label),
          );
        case HealthRegularizationRecordedPayload(:final amount, :final label):
          next = _requireEnabled(next)._withEntry(
            _entry(entry.event, HealthEntryKind.regularization, amount, label),
          );
        case HealthEntryReversedPayload(:final entryEventId):
          if (next == null) {
            throw const ProjectionConflictException(
              'A health entry was reversed before tracking existed.',
            );
          }
          next = next._reverseEntry(entry.event, entryEventId);
        default:
          throw UnsupportedEventException(entry.event.eventType);
      }
    }
    return HealthLedger._(
      tracking: next,
      appliedEventIds: {..._appliedEventIds, entry.event.id},
      lastPosition: entry.position,
    );
  }
}

ProjectedHealthTracking _requireEnabled(ProjectedHealthTracking? tracking) {
  if (tracking == null || !tracking.enabled) {
    throw const ProjectionConflictException(
      'Health entries require enabled tracking.',
    );
  }
  return tracking;
}

ProjectedHealthEntry _entry(
  EventRecord event,
  HealthEntryKind kind,
  Money amount,
  String label,
) => ProjectedHealthEntry._(
  eventId: event.id,
  kind: kind,
  amount: amount,
  label: label,
  businessDate: event.businessDate,
  recordedAtUtc: event.recordedAtUtc,
);
