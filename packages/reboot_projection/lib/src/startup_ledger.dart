import 'package:reboot_domain/reboot_domain.dart';

import 'projection_errors.dart';

/// Replayable startup assessment and explicit user acceptance.
final class StartupLedger {
  StartupLedger._({
    required this.planId,
    required this.liquidity,
    required this.householdNeeds,
    required this.cushionPolicy,
    required this.assessment,
    required this.acceptedPlan,
    required Set<EventId> appliedEventIds,
    required this.lastPosition,
  }) : _appliedEventIds = Set<EventId>.unmodifiable(appliedEventIds);

  factory StartupLedger.empty() => StartupLedger._(
    planId: null,
    liquidity: null,
    householdNeeds: null,
    cushionPolicy: null,
    assessment: null,
    acceptedPlan: null,
    appliedEventIds: const {},
    lastPosition: null,
  );

  factory StartupLedger.replay(Iterable<LocalJournalEntry> entries) => entries
      .fold(StartupLedger.empty(), (ledger, entry) => ledger.apply(entry));

  final EntityId? planId;
  final LiquiditySnapshot? liquidity;
  final HouseholdNeedsProfile? householdNeeds;
  final CashCushionPolicyCreatedPayload? cushionPolicy;
  final LaunchAssessmentCreatedPayload? assessment;
  final LaunchPlanAcceptedPayload? acceptedPlan;
  final Set<EventId> _appliedEventIds;
  final LocalJournalPosition? lastPosition;

  bool get isReady => acceptedPlan != null;

  StartupLedger apply(LocalJournalEntry entry) {
    if (_appliedEventIds.contains(entry.event.id)) return this;
    if (lastPosition != null && entry.position.compareTo(lastPosition!) <= 0) {
      throw LocalJournalOrderException(
        previous: lastPosition!,
        received: entry.position,
      );
    }

    var nextPlanId = planId;
    var nextLiquidity = liquidity;
    var nextNeeds = householdNeeds;
    var nextCushion = cushionPolicy;
    var nextAssessment = assessment;
    var nextAccepted = acceptedPlan;
    if (entry.event.target.kind == EntityKind.startupPlan) {
      if (nextPlanId != null && nextPlanId != entry.event.target.id) {
        throw const ProjectionConflictException(
          'One household cannot have two startup plan identities.',
        );
      }
      nextPlanId ??= entry.event.target.id;
      switch (entry.event.payload) {
        case LiquiditySnapshotCreatedPayload(:final snapshot):
          if (nextLiquidity != null) {
            throw const ProjectionConflictException(
              'The initial startup liquidity was recorded more than once.',
            );
          }
          nextLiquidity = snapshot;
        case HouseholdNeedsProfileCreatedPayload(:final profile):
          if (nextNeeds != null) {
            throw const ProjectionConflictException(
              'The initial household needs were recorded more than once.',
            );
          }
          nextNeeds = profile;
        case CashCushionPolicyCreatedPayload():
          if (nextLiquidity == null || nextCushion != null) {
            throw const ProjectionConflictException(
              'A cushion policy requires one prior liquidity snapshot.',
            );
          }
          nextCushion = entry.event.payload as CashCushionPolicyCreatedPayload;
        case LaunchAssessmentCreatedPayload():
          if (nextLiquidity == null ||
              nextNeeds == null ||
              nextCushion == null ||
              nextAssessment != null) {
            throw const ProjectionConflictException(
              'A launch assessment requires all confirmed startup inputs.',
            );
          }
          final payload = entry.event.payload as LaunchAssessmentCreatedPayload;
          if (payload.minimumViableWeeklyBudget !=
              nextNeeds.minimumViableWeeklyBudget) {
            throw const ProjectionConflictException(
              'The assessment minimum differs from the household declaration.',
            );
          }
          nextAssessment = payload;
        case LaunchPlanAcceptedPayload():
          if (nextAssessment == null ||
              nextCushion == null ||
              nextAccepted != null) {
            throw const ProjectionConflictException(
              'A launch plan requires one prior assessment.',
            );
          }
          final payload = entry.event.payload as LaunchPlanAcceptedPayload;
          if (payload.sustainableWeeklyBudget !=
              nextAssessment.sustainableWeeklyBudget) {
            throw const ProjectionConflictException(
              'The accepted plan changed the assessed sustainable budget.',
            );
          }
          if (nextCushion.overdraftFundedCash.isPositive &&
              !payload.acceptedBankFundingRisk) {
            throw const ProjectionConflictException(
              'Bank-funded cushion risk must be explicitly accepted.',
            );
          }
          nextAccepted = payload;
        default:
          throw UnsupportedEventException(entry.event.eventType);
      }
    }

    return StartupLedger._(
      planId: nextPlanId,
      liquidity: nextLiquidity,
      householdNeeds: nextNeeds,
      cushionPolicy: nextCushion,
      assessment: nextAssessment,
      acceptedPlan: nextAccepted,
      appliedEventIds: {..._appliedEventIds, entry.event.id},
      lastPosition: entry.position,
    );
  }
}
