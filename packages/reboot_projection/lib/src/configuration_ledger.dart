import 'package:reboot_domain/reboot_domain.dart';

import 'annualization.dart';
import 'projection_errors.dart';

/// Household settings reconstructed from their immutable event history.
final class ProjectedHousehold {
  ProjectedHousehold._({
    required this.id,
    required this.householdKind,
    required this.currency,
    required List<CyclePolicy> cyclePolicies,
    required this.createdByEventId,
    required this.createdAtUtc,
  }) : cyclePolicies = List<CyclePolicy>.unmodifiable(cyclePolicies);

  factory ProjectedHousehold._created(EventRecord event) {
    final payload = event.payload as HouseholdCreatedPayload;
    return ProjectedHousehold._(
      id: event.target.id,
      householdKind: payload.householdKind,
      currency: payload.currency,
      cyclePolicies: [payload.initialCyclePolicy],
      createdByEventId: event.id,
      createdAtUtc: event.recordedAtUtc,
    );
  }

  /// Stable identity of the local household.
  final EntityId id;

  /// Solo or shared-principal-account mode.
  final HouseholdKind householdKind;

  /// Explicit household currency.
  final Currency currency;

  /// Complete, ordered cycle-policy history.
  final List<CyclePolicy> cyclePolicies;

  /// Event that established this household.
  final EventId createdByEventId;

  /// UTC instant at which onboarding established the household.
  final DateTime createdAtUtc;

  /// Initial materialized weekly cycle start.
  LocalDate get firstCycleStart => cyclePolicies.first.firstNormalCycleStart;

  /// Most recently accepted policy.
  CyclePolicy get latestCyclePolicy => cyclePolicies.last;

  /// Resolves the latest policy whose normal cycles have begun by [cycleStart].
  CyclePolicy policyForCycleStarting(LocalDate cycleStart) {
    CyclePolicy? result;
    for (final policy in cyclePolicies) {
      if (!policy.firstNormalCycleStart.isAfter(cycleStart)) {
        result = policy;
      }
    }
    if (result == null) {
      throw StateError(
        'Cycle $cycleStart precedes the household configuration.',
      );
    }
    return result;
  }

  /// Materializes the historical cycle containing [date].
  ///
  /// Scheduled anchor changes create their explicit transition cycle instead
  /// of pretending that every cycle always contains seven dates.
  WeeklyCycle cycleContaining(LocalDate date) {
    if (date.isBefore(firstCycleStart)) {
      throw StateError('Date $date precedes the household configuration.');
    }

    var currentPolicy = cyclePolicies.first;
    for (final nextPolicy in cyclePolicies.skip(1)) {
      if (currentPolicy.anchorWeekday == nextPolicy.anchorWeekday) {
        if (date.isBefore(nextPolicy.firstNormalCycleStart)) {
          return CycleCalendar.normalCycleContaining(
            date: date,
            policy: currentPolicy,
          );
        }
      } else {
        final change = CycleCalendar.changeAnchor(
          previousPolicy: currentPolicy,
          nextPolicy: nextPolicy,
        );
        if (date.isBefore(change.transition.start)) {
          return CycleCalendar.normalCycleContaining(
            date: date,
            policy: currentPolicy,
          );
        }
        if (change.transition.contains(date)) {
          return change.transition;
        }
      }
      currentPolicy = nextPolicy;
    }

    return CycleCalendar.normalCycleContaining(
      date: date,
      policy: currentPolicy,
    );
  }

  /// Returns [count] gap-free cycles beginning with the one containing [date].
  List<WeeklyCycle> cyclesFromDate(LocalDate date, {required int count}) {
    if (count < 1) {
      throw RangeError.range(count, 1, null, 'count');
    }
    final cycles = <WeeklyCycle>[cycleContaining(date)];
    while (cycles.length < count) {
      cycles.add(cycleContaining(cycles.last.endExclusive));
    }
    return List<WeeklyCycle>.unmodifiable(cycles);
  }

  ProjectedHousehold _changedBy(EventRecord event) {
    final payload = event.payload as HouseholdCyclePolicyChangedPayload;
    final next = payload.nextPolicy;
    final previous = latestCyclePolicy;
    if (next.version <= previous.version) {
      throw ProjectionConflictException(
        'Cycle policy ${next.version} does not follow version '
        '${previous.version}.',
      );
    }
    if (next.effectiveFrom.isBefore(event.businessDate)) {
      throw ProjectionConflictException(
        'A cycle-policy change cannot take effect retroactively.',
      );
    }
    if (!next.firstNormalCycleStart.isAfter(previous.firstNormalCycleStart)) {
      throw ProjectionConflictException(
        'A new cycle policy must begin after the previous policy.',
      );
    }

    return ProjectedHousehold._(
      id: id,
      householdKind: householdKind,
      currency: currency,
      cyclePolicies: [...cyclePolicies, next],
      createdByEventId: createdByEventId,
      createdAtUtc: createdAtUtc,
    );
  }
}

/// One accepted version or tombstone in a cash-flow history.
final class CashFlowRevision {
  const CashFlowRevision({
    required this.effectiveFromCycleStart,
    required this.eventId,
    required this.recordedAtUtc,
    required this.definition,
  });

  /// First cycle affected by this revision.
  final LocalDate effectiveFromCycleStart;

  /// Immutable source event.
  final EventId eventId;

  /// Audit instant.
  final DateTime recordedAtUtc;

  /// Complete definition, or `null` for a tombstone.
  final CashFlowDefinition? definition;

  /// Whether this revision removes the cash flow.
  bool get isDeletion => definition == null;
}

/// One recurring assumption with all of its accepted historical versions.
final class ProjectedCashFlow {
  ProjectedCashFlow._({
    required this.id,
    required List<CashFlowRevision> revisions,
  }) : revisions = List<CashFlowRevision>.unmodifiable(revisions);

  factory ProjectedCashFlow._created(EventRecord event) {
    final payload = event.payload as CashFlowCreatedPayload;
    return ProjectedCashFlow._(
      id: event.target.id,
      revisions: [
        CashFlowRevision(
          effectiveFromCycleStart: payload.effectiveFromCycleStart,
          eventId: event.id,
          recordedAtUtc: event.recordedAtUtc,
          definition: payload.definition,
        ),
      ],
    );
  }

  /// Stable cash-flow identity across replacements.
  final EntityId id;

  /// Ordered accepted versions, ending with an optional tombstone.
  final List<CashFlowRevision> revisions;

  /// Last accepted revision.
  CashFlowRevision get latestRevision => revisions.last;

  /// Complete definition effective for [cycleStart], or `null` when absent.
  CashFlowDefinition? definitionForCycleStarting(LocalDate cycleStart) {
    CashFlowRevision? effective;
    for (final revision in revisions) {
      if (!revision.effectiveFromCycleStart.isAfter(cycleStart)) {
        effective = revision;
      }
    }
    return effective?.definition;
  }

  ProjectedCashFlow _replacedBy(EventRecord event) {
    if (latestRevision.isDeletion) {
      throw ProjectionConflictException(
        'Deleted cash flow $id cannot be replaced.',
      );
    }
    final payload = event.payload as CashFlowReplacedPayload;
    _validateNextEffectiveDate(
      payload.effectiveFromCycleStart,
      event.businessDate,
    );
    return ProjectedCashFlow._(
      id: id,
      revisions: [
        ...revisions,
        CashFlowRevision(
          effectiveFromCycleStart: payload.effectiveFromCycleStart,
          eventId: event.id,
          recordedAtUtc: event.recordedAtUtc,
          definition: payload.definition,
        ),
      ],
    );
  }

  ProjectedCashFlow _deletedBy(EventRecord event) {
    if (latestRevision.isDeletion) {
      throw ProjectionConflictException(
        'Cash flow $id received multiple tombstones.',
      );
    }
    final payload = event.payload as CashFlowDeletedPayload;
    _validateNextEffectiveDate(
      payload.effectiveFromCycleStart,
      event.businessDate,
    );
    return ProjectedCashFlow._(
      id: id,
      revisions: [
        ...revisions,
        CashFlowRevision(
          effectiveFromCycleStart: payload.effectiveFromCycleStart,
          eventId: event.id,
          recordedAtUtc: event.recordedAtUtc,
          definition: null,
        ),
      ],
    );
  }

  void _validateNextEffectiveDate(
    LocalDate effectiveFromCycleStart,
    LocalDate businessDate,
  ) {
    if (effectiveFromCycleStart.isBefore(businessDate)) {
      throw ProjectionConflictException(
        'A cash-flow change cannot take effect retroactively.',
      );
    }
    if (effectiveFromCycleStart.isBefore(
      latestRevision.effectiveFromCycleStart,
    )) {
      throw ProjectionConflictException(
        'Cash-flow effective dates cannot move backwards.',
      );
    }
  }
}

/// One accepted already-received bonus snapshot or future tombstone.
final class ReceivedBonusRevision {
  const ReceivedBonusRevision({
    required this.effectiveFromCycleStart,
    required this.eventId,
    required this.recordedAtUtc,
    required this.pool,
  });

  /// First weekly cycle affected by this snapshot.
  final LocalDate effectiveFromCycleStart;

  /// Immutable source event.
  final EventId eventId;

  /// UTC instant at which the user confirmed the amount.
  final DateTime recordedAtUtc;

  /// Complete pool, or `null` when this revision stops the allocation.
  final ReceivedBonusPool? pool;

  bool get isDeletion => pool == null;
}

/// Replayable history of one recurring bonus source.
final class ProjectedReceivedBonus {
  ProjectedReceivedBonus._({
    required this.id,
    required List<ReceivedBonusRevision> revisions,
  }) : revisions = List<ReceivedBonusRevision>.unmodifiable(revisions);

  factory ProjectedReceivedBonus._created(EventRecord event) {
    final payload = event.payload as ReceivedBonusCreatedPayload;
    return ProjectedReceivedBonus._(
      id: event.target.id,
      revisions: [
        ReceivedBonusRevision(
          effectiveFromCycleStart: payload.effectiveFromCycleStart,
          eventId: event.id,
          recordedAtUtc: event.recordedAtUtc,
          pool: payload.pool,
        ),
      ],
    );
  }

  final EntityId id;
  final List<ReceivedBonusRevision> revisions;

  ReceivedBonusRevision get latestRevision => revisions.last;

  /// Complete snapshot effective for [cycleStart], including a tombstone.
  ReceivedBonusRevision? revisionForCycleStarting(LocalDate cycleStart) {
    ReceivedBonusRevision? effective;
    for (final revision in revisions) {
      if (!revision.effectiveFromCycleStart.isAfter(cycleStart)) {
        effective = revision;
      }
    }
    return effective;
  }

  ProjectedReceivedBonus _replacedBy(EventRecord event) {
    if (latestRevision.isDeletion) {
      throw ProjectionConflictException(
        'Deleted received bonus $id cannot be replaced.',
      );
    }
    final payload = event.payload as ReceivedBonusReplacedPayload;
    _validateNextEffectiveDate(
      payload.effectiveFromCycleStart,
      event.businessDate,
    );
    return ProjectedReceivedBonus._(
      id: id,
      revisions: [
        ...revisions,
        ReceivedBonusRevision(
          effectiveFromCycleStart: payload.effectiveFromCycleStart,
          eventId: event.id,
          recordedAtUtc: event.recordedAtUtc,
          pool: payload.pool,
        ),
      ],
    );
  }

  ProjectedReceivedBonus _deletedBy(EventRecord event) {
    if (latestRevision.isDeletion) {
      throw ProjectionConflictException(
        'Received bonus $id received multiple tombstones.',
      );
    }
    final payload = event.payload as ReceivedBonusDeletedPayload;
    _validateNextEffectiveDate(
      payload.effectiveFromCycleStart,
      event.businessDate,
    );
    return ProjectedReceivedBonus._(
      id: id,
      revisions: [
        ...revisions,
        ReceivedBonusRevision(
          effectiveFromCycleStart: payload.effectiveFromCycleStart,
          eventId: event.id,
          recordedAtUtc: event.recordedAtUtc,
          pool: null,
        ),
      ],
    );
  }

  void _validateNextEffectiveDate(
    LocalDate effectiveFromCycleStart,
    LocalDate businessDate,
  ) {
    if (effectiveFromCycleStart.isBefore(businessDate)) {
      throw ProjectionConflictException(
        'A received-bonus change cannot take effect retroactively.',
      );
    }
    if (effectiveFromCycleStart.isBefore(
      latestRevision.effectiveFromCycleStart,
    )) {
      throw ProjectionConflictException(
        'Received-bonus effective dates cannot move backwards.',
      );
    }
  }
}

/// One complete annual reserve, project, and safety snapshot.
final class AnnualCommitmentsRevision {
  const AnnualCommitmentsRevision({
    required this.effectiveFromCycleStart,
    required this.reserveContributions,
    required this.projectContributions,
    required this.safetyMargin,
    required this.eventId,
    required this.recordedAtUtc,
    this.strategy = TrajectoryStrategy.balance,
    this.overdraftExitGoal,
  });

  /// First cycle affected by this snapshot.
  final LocalDate effectiveFromCycleStart;

  /// Annual amount directed to reserves.
  final Money reserveContributions;

  /// Annual amount directed to projects.
  final Money projectContributions;

  /// Additional annual safety margin.
  final Money safetyMargin;

  /// Immutable source event.
  final EventId eventId;

  /// Audit instant.
  final DateTime recordedAtUtc;

  /// Explicit reason for keeping capacity outside weekly spending.
  final TrajectoryStrategy strategy;

  /// Time-bound recovery goal in overdraft-exit mode.
  final OverdraftExitGoal? overdraftExitGoal;

  /// Converts this domain event projection into annualization input.
  AnnualBudgetDeductions toDeductions(Currency currency) {
    return AnnualBudgetDeductions(
      currency: currency,
      reserveContributions: reserveContributions,
      projectContributions: projectContributions,
      safetyMargin: safetyMargin,
    );
  }
}

/// Replayable household configuration derived from the global local journal.
final class ConfigurationLedger {
  ConfigurationLedger._({
    required this.household,
    required Map<EntityId, ProjectedCashFlow> cashFlows,
    required Map<EntityId, ProjectedReceivedBonus> receivedBonuses,
    required this.annualBudgetPlanId,
    required List<AnnualCommitmentsRevision> annualCommitments,
    required Set<EventId> appliedEventIds,
    required this.lastPosition,
  }) : cashFlows = Map<EntityId, ProjectedCashFlow>.unmodifiable(cashFlows),
       receivedBonuses = Map<EntityId, ProjectedReceivedBonus>.unmodifiable(
         receivedBonuses,
       ),
       annualCommitments = List<AnnualCommitmentsRevision>.unmodifiable(
         annualCommitments,
       ),
       _appliedEventIds = Set<EventId>.unmodifiable(appliedEventIds);

  /// Creates an empty configuration projection.
  factory ConfigurationLedger.empty() {
    return ConfigurationLedger._(
      household: null,
      cashFlows: const {},
      receivedBonuses: const {},
      annualBudgetPlanId: null,
      annualCommitments: const [],
      appliedEventIds: const {},
      lastPosition: null,
    );
  }

  /// Replays the complete global journal, ignoring expense event families.
  factory ConfigurationLedger.replay(Iterable<LocalJournalEntry> entries) {
    return entries.fold(
      ConfigurationLedger.empty(),
      (ledger, entry) => ledger.apply(entry),
    );
  }

  /// The one local household, once onboarding has established it.
  final ProjectedHousehold? household;

  /// All cash-flow histories, including future-effective tombstones.
  final Map<EntityId, ProjectedCashFlow> cashFlows;

  /// Already-received bonus sources with all confirmed snapshots.
  final Map<EntityId, ProjectedReceivedBonus> receivedBonuses;

  /// Stable aggregate identity used for annual commitments.
  final EntityId? annualBudgetPlanId;

  /// Ordered annual commitment snapshots.
  final List<AnnualCommitmentsRevision> annualCommitments;

  final Set<EventId> _appliedEventIds;

  /// Last non-duplicate global journal position applied.
  final LocalJournalPosition? lastPosition;

  /// Returns active definitions for the requested weekly cycle.
  List<CashFlowDefinition> cashFlowsForCycleStarting(LocalDate cycleStart) {
    return List<CashFlowDefinition>.unmodifiable(
      cashFlows.values
          .map((projected) => projected.definitionForCycleStarting(cycleStart))
          .nonNulls,
    );
  }

  /// Exact already-existing bonus amount assigned to one weekly cycle.
  Money receivedBonusForCycleStarting(LocalDate cycleStart) {
    final configuredHousehold = household;
    if (configuredHousehold == null) {
      throw const IncompleteConfigurationException(
        'The household has not been configured.',
      );
    }
    var total = Money.zero(configuredHousehold.currency);
    for (final projected in receivedBonuses.values) {
      final revision = projected.revisionForCycleStarting(cycleStart);
      final pool = revision?.pool;
      if (revision == null || pool == null) continue;
      final allocation = ReceivedBonusAllocator.allocate(
        pool: pool,
        cyclesCoveringPaymentDate: _cyclesCoveringPaymentDate(
          configuredHousehold,
          revision.effectiveFromCycleStart,
          pool.nextPaymentDate,
        ),
      );
      total += allocation.amountFor(cycleStart);
    }
    return total;
  }

  /// Returns the latest annual commitments active for [cycleStart].
  AnnualCommitmentsRevision? commitmentsForCycleStarting(LocalDate cycleStart) {
    AnnualCommitmentsRevision? effective;
    for (final revision in annualCommitments) {
      if (!revision.effectiveFromCycleStart.isAfter(cycleStart)) {
        effective = revision;
      }
    }
    return effective;
  }

  /// Produces the accepted annual recommendation at the horizon's first cycle.
  AnnualBudgetProjection buildAnnualBudget(List<WeeklyCycle> cycles) {
    final configuredHousehold = household;
    if (configuredHousehold == null) {
      throw const IncompleteConfigurationException(
        'The household has not been configured.',
      );
    }
    if (cycles.isEmpty) {
      throw ArgumentError.value(cycles, 'cycles', 'A horizon is required.');
    }
    final expectedPolicy = configuredHousehold.policyForCycleStarting(
      cycles.first.start,
    );
    if (cycles.first.policy != expectedPolicy) {
      throw ProjectionConflictException(
        'The first cycle does not use the configured household policy.',
      );
    }

    final commitments = commitmentsForCycleStarting(cycles.first.start);
    return AnnualizationEngine.project(
      cycles: cycles,
      cashFlows: cashFlowsForCycleStarting(cycles.first.start),
      deductions:
          commitments?.toDeductions(configuredHousehold.currency) ??
          AnnualBudgetDeductions(currency: configuredHousehold.currency),
      overdraftExitGoal: commitments?.overdraftExitGoal,
    );
  }

  /// Applies one ordered global journal entry and returns a new projection.
  ///
  /// Reapplying an already-seen event UUID returns this exact instance.
  ConfigurationLedger apply(LocalJournalEntry entry) {
    if (_appliedEventIds.contains(entry.event.id)) {
      return this;
    }
    if (lastPosition != null && entry.position.compareTo(lastPosition!) <= 0) {
      throw LocalJournalOrderException(
        previous: lastPosition!,
        received: entry.position,
      );
    }

    var nextHousehold = household;
    final nextCashFlows = Map<EntityId, ProjectedCashFlow>.of(cashFlows);
    final nextReceivedBonuses = Map<EntityId, ProjectedReceivedBonus>.of(
      receivedBonuses,
    );
    var nextPlanId = annualBudgetPlanId;
    final nextCommitments = List<AnnualCommitmentsRevision>.of(
      annualCommitments,
    );

    switch (entry.event.target.kind) {
      case EntityKind.household:
        switch (entry.event.payload) {
          case HouseholdCreatedPayload():
            if (nextHousehold != null) {
              throw const ProjectionConflictException(
                'The journal contains multiple household creation events.',
              );
            }
            nextHousehold = ProjectedHousehold._created(entry.event);
          case HouseholdCyclePolicyChangedPayload():
            final existing = nextHousehold;
            if (existing == null || existing.id != entry.event.target.id) {
              throw const ProjectionConflictException(
                'A cycle policy changed before its household existed.',
              );
            }
            nextHousehold = existing._changedBy(entry.event);
          default:
            throw UnsupportedEventException(entry.event.eventType);
        }
      case EntityKind.cashFlow:
        final configuredHousehold = nextHousehold;
        if (configuredHousehold == null) {
          throw const ProjectionConflictException(
            'A cash flow was configured before the household existed.',
          );
        }
        switch (entry.event.payload) {
          case CashFlowCreatedPayload():
            final payload = entry.event.payload as CashFlowCreatedPayload;
            _requireConfiguredCycleStart(
              configuredHousehold,
              payload.effectiveFromCycleStart,
              'Cash flow',
            );
            _requireHouseholdCurrency(configuredHousehold, payload.definition);
            if (nextCashFlows.containsKey(entry.event.target.id)) {
              throw ProjectionConflictException(
                'Cash flow ${entry.event.target.id} was created more than once.',
              );
            }
            nextCashFlows[entry.event.target.id] = ProjectedCashFlow._created(
              entry.event,
            );
          case CashFlowReplacedPayload():
            final payload = entry.event.payload as CashFlowReplacedPayload;
            _requireConfiguredCycleStart(
              configuredHousehold,
              payload.effectiveFromCycleStart,
              'Cash flow replacement',
            );
            _requireHouseholdCurrency(configuredHousehold, payload.definition);
            final existing = nextCashFlows[entry.event.target.id];
            if (existing == null) {
              throw ProjectionConflictException(
                'Cash flow ${entry.event.target.id} was replaced before creation.',
              );
            }
            nextCashFlows[entry.event.target.id] = existing._replacedBy(
              entry.event,
            );
          case CashFlowDeletedPayload():
            final payload = entry.event.payload as CashFlowDeletedPayload;
            _requireConfiguredCycleStart(
              configuredHousehold,
              payload.effectiveFromCycleStart,
              'Cash flow deletion',
            );
            final existing = nextCashFlows[entry.event.target.id];
            if (existing == null) {
              throw ProjectionConflictException(
                'Cash flow ${entry.event.target.id} was deleted before creation.',
              );
            }
            nextCashFlows[entry.event.target.id] = existing._deletedBy(
              entry.event,
            );
          default:
            throw UnsupportedEventException(entry.event.eventType);
        }
      case EntityKind.receivedBonus:
        final configuredHousehold = nextHousehold;
        if (configuredHousehold == null) {
          throw const ProjectionConflictException(
            'A received bonus was configured before the household existed.',
          );
        }
        switch (entry.event.payload) {
          case ReceivedBonusCreatedPayload():
            final payload = entry.event.payload as ReceivedBonusCreatedPayload;
            _validateReceivedBonus(
              configuredHousehold,
              payload.pool,
              payload.effectiveFromCycleStart,
              entry.event.businessDate,
            );
            if (nextReceivedBonuses.containsKey(entry.event.target.id)) {
              throw ProjectionConflictException(
                'Received bonus ${entry.event.target.id} was created more than once.',
              );
            }
            nextReceivedBonuses[entry.event.target.id] =
                ProjectedReceivedBonus._created(entry.event);
          case ReceivedBonusReplacedPayload():
            final payload = entry.event.payload as ReceivedBonusReplacedPayload;
            _validateReceivedBonus(
              configuredHousehold,
              payload.pool,
              payload.effectiveFromCycleStart,
              entry.event.businessDate,
            );
            final existing = nextReceivedBonuses[entry.event.target.id];
            if (existing == null) {
              throw ProjectionConflictException(
                'Received bonus ${entry.event.target.id} was replaced before creation.',
              );
            }
            nextReceivedBonuses[entry.event.target.id] = existing._replacedBy(
              entry.event,
            );
          case ReceivedBonusDeletedPayload():
            final payload = entry.event.payload as ReceivedBonusDeletedPayload;
            _requireConfiguredCycleStart(
              configuredHousehold,
              payload.effectiveFromCycleStart,
              'Received bonus deletion',
            );
            final existing = nextReceivedBonuses[entry.event.target.id];
            if (existing == null) {
              throw ProjectionConflictException(
                'Received bonus ${entry.event.target.id} was deleted before creation.',
              );
            }
            nextReceivedBonuses[entry.event.target.id] = existing._deletedBy(
              entry.event,
            );
          default:
            throw UnsupportedEventException(entry.event.eventType);
        }
      case EntityKind.annualBudgetPlan:
        final configuredHousehold = nextHousehold;
        if (configuredHousehold == null) {
          throw const ProjectionConflictException(
            'Annual commitments were configured before the household existed.',
          );
        }
        switch (entry.event.payload) {
          case AnnualCommitmentsSetPayload():
            final payload = entry.event.payload as AnnualCommitmentsSetPayload;
            _requireConfiguredCycleStart(
              configuredHousehold,
              payload.effectiveFromCycleStart,
              'Annual commitments',
            );
            if (nextPlanId != null && nextPlanId != entry.event.target.id) {
              throw const ProjectionConflictException(
                'The journal contains multiple annual budget plans.',
              );
            }
            if (nextCommitments.isNotEmpty) {
              final previous = nextCommitments.last;
              if (payload.effectiveFromCycleStart.isBefore(
                entry.event.businessDate,
              )) {
                throw const ProjectionConflictException(
                  'Annual commitments cannot change retroactively.',
                );
              }
              if (payload.effectiveFromCycleStart.isBefore(
                previous.effectiveFromCycleStart,
              )) {
                throw const ProjectionConflictException(
                  'Annual commitment effective dates cannot move backwards.',
                );
              }
            }
            nextPlanId = entry.event.target.id;
            nextCommitments.add(
              AnnualCommitmentsRevision(
                effectiveFromCycleStart: payload.effectiveFromCycleStart,
                reserveContributions: payload.reserveContributions,
                projectContributions: payload.projectContributions,
                safetyMargin: payload.safetyMargin,
                eventId: entry.event.id,
                recordedAtUtc: entry.event.recordedAtUtc,
              ),
            );
          case TrajectoryPlanSetPayload():
            final payload = entry.event.payload as TrajectoryPlanSetPayload;
            _requireConfiguredCycleStart(
              configuredHousehold,
              payload.effectiveFromCycleStart,
              'Trajectory plan',
            );
            if (payload.overdraftExitGoal case final goal?
                when !goal.targetDate.isAfter(entry.event.businessDate)) {
              throw const ProjectionConflictException(
                'An overdraft target must be after its confirmation date.',
              );
            }
            if (nextPlanId != null && nextPlanId != entry.event.target.id) {
              throw const ProjectionConflictException(
                'The journal contains multiple annual budget plans.',
              );
            }
            if (nextCommitments.isNotEmpty) {
              final previous = nextCommitments.last;
              if (payload.effectiveFromCycleStart.isBefore(
                entry.event.businessDate,
              )) {
                throw const ProjectionConflictException(
                  'A trajectory plan cannot change retroactively.',
                );
              }
              if (payload.effectiveFromCycleStart.isBefore(
                previous.effectiveFromCycleStart,
              )) {
                throw const ProjectionConflictException(
                  'Trajectory effective dates cannot move backwards.',
                );
              }
            }
            nextPlanId = entry.event.target.id;
            nextCommitments.add(
              AnnualCommitmentsRevision(
                effectiveFromCycleStart: payload.effectiveFromCycleStart,
                reserveContributions: payload.reserveContributions,
                projectContributions: payload.projectContributions,
                safetyMargin: payload.safetyMargin,
                eventId: entry.event.id,
                recordedAtUtc: entry.event.recordedAtUtc,
                strategy: payload.strategy,
                overdraftExitGoal: payload.overdraftExitGoal,
              ),
            );
          default:
            throw UnsupportedEventException(entry.event.eventType);
        }
      case EntityKind.expense:
      case EntityKind.reserve:
      case EntityKind.healthTracking:
      case EntityKind.cashHandling:
        // Operational facts share the journal but do not alter configuration.
        break;
    }

    return ConfigurationLedger._(
      household: nextHousehold,
      cashFlows: nextCashFlows,
      receivedBonuses: nextReceivedBonuses,
      annualBudgetPlanId: nextPlanId,
      annualCommitments: nextCommitments,
      appliedEventIds: {..._appliedEventIds, entry.event.id},
      lastPosition: entry.position,
    );
  }
}

List<WeeklyCycle> _cyclesCoveringPaymentDate(
  ProjectedHousehold household,
  LocalDate firstCycleStart,
  LocalDate paymentDate,
) {
  final cycles = <WeeklyCycle>[household.cycleContaining(firstCycleStart)];
  while (cycles.last.endExclusive.isBefore(paymentDate)) {
    cycles.add(household.cycleContaining(cycles.last.endExclusive));
  }
  return List<WeeklyCycle>.unmodifiable(cycles);
}

void _validateReceivedBonus(
  ProjectedHousehold household,
  ReceivedBonusPool pool,
  LocalDate effectiveFromCycleStart,
  LocalDate businessDate,
) {
  _requireConfiguredCycleStart(
    household,
    effectiveFromCycleStart,
    'Received bonus',
  );
  if (pool.remainingForDailyLife.currency != household.currency) {
    throw CurrencyMismatchException(
      household.currency,
      pool.remainingForDailyLife.currency,
    );
  }
  if (effectiveFromCycleStart.isBefore(businessDate)) {
    throw const ProjectionConflictException(
      'A received bonus cannot take effect retroactively.',
    );
  }
  if (!pool.nextPaymentDate.isAfter(effectiveFromCycleStart)) {
    throw const ProjectionConflictException(
      'A received bonus must cover at least one future REBOOT cycle.',
    );
  }
}

void _requireConfiguredCycleStart(
  ProjectedHousehold household,
  LocalDate cycleStart,
  String label,
) {
  final policy = household.policyForCycleStarting(cycleStart);
  if (cycleStart.weekday != policy.anchorWeekday) {
    throw ProjectionConflictException(
      '$label must take effect on a configured REBOOT cycle start.',
    );
  }
}

void _requireHouseholdCurrency(
  ProjectedHousehold household,
  CashFlowDefinition definition,
) {
  final currency = definition.referenceAmountPerOccurrence.currency;
  if (currency != household.currency) {
    throw CurrencyMismatchException(household.currency, currency);
  }
}

/// Indicates that a required onboarding fact is still absent.
final class IncompleteConfigurationException implements Exception {
  /// Creates an incomplete-configuration error.
  const IncompleteConfigurationException(this.message);

  /// Developer-facing diagnostic.
  final String message;

  @override
  String toString() => 'IncompleteConfigurationException: $message';
}
