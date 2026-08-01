import 'package:reboot_domain/reboot_domain.dart';

import 'projection_errors.dart';

/// One accepted cash-withdrawal method and its civil effective date.
final class CashMethodRevision {
  const CashMethodRevision({
    required this.method,
    required this.effectiveFrom,
    required this.eventId,
    required this.recordedAtUtc,
  });

  final CashWithdrawalMethod method;
  final LocalDate effectiveFrom;
  final EventId eventId;
  final DateTime recordedAtUtc;
}

/// One transfer to the conceptual cash wallet and any later correction.
final class ProjectedCashWalletTransfer {
  const ProjectedCashWalletTransfer._({
    required this.eventId,
    required this.amount,
    required this.label,
    required this.businessDate,
    required this.recordedAtUtc,
    this.reversalEventId,
  });

  final EventId eventId;
  final Money amount;
  final String label;
  final LocalDate businessDate;
  final DateTime recordedAtUtc;
  final EventId? reversalEventId;

  bool get isReversed => reversalEventId != null;

  ProjectedCashWalletTransfer _reversedBy(EventRecord event) =>
      ProjectedCashWalletTransfer._(
        eventId: eventId,
        amount: amount,
        label: label,
        businessDate: businessDate,
        recordedAtUtc: recordedAtUtc,
        reversalEventId: event.id,
      );
}

/// Replayable cash method history and transfer audit trail.
final class CashLedger {
  CashLedger._({
    required this.id,
    required List<CashMethodRevision> methodRevisions,
    required List<ProjectedCashWalletTransfer> walletTransfers,
    required Set<EventId> appliedEventIds,
    required this.lastPosition,
  }) : methodRevisions = List<CashMethodRevision>.unmodifiable(methodRevisions),
       walletTransfers = List<ProjectedCashWalletTransfer>.unmodifiable(
         walletTransfers,
       ),
       _appliedEventIds = Set<EventId>.unmodifiable(appliedEventIds);

  factory CashLedger.empty() => CashLedger._(
    id: null,
    methodRevisions: const [],
    walletTransfers: const [],
    appliedEventIds: const {},
    lastPosition: null,
  );

  factory CashLedger.replay(Iterable<LocalJournalEntry> entries) =>
      entries.fold(CashLedger.empty(), (ledger, entry) => ledger.apply(entry));

  final EntityId? id;
  final List<CashMethodRevision> methodRevisions;
  final List<ProjectedCashWalletTransfer> walletTransfers;
  final Set<EventId> _appliedEventIds;
  final LocalJournalPosition? lastPosition;

  Iterable<ProjectedCashWalletTransfer> get activeWalletTransfers =>
      walletTransfers.where((transfer) => !transfer.isReversed);

  CashMethodRevision? get latestMethodRevision =>
      methodRevisions.isEmpty ? null : methodRevisions.last;

  CashWithdrawalMethod? methodOn(LocalDate date) {
    CashMethodRevision? effective;
    for (final revision in methodRevisions) {
      if (!revision.effectiveFrom.isAfter(date)) effective = revision;
    }
    return effective?.method;
  }

  CashLedger apply(LocalJournalEntry entry) {
    if (_appliedEventIds.contains(entry.event.id)) return this;
    if (lastPosition != null && entry.position.compareTo(lastPosition!) <= 0) {
      throw LocalJournalOrderException(
        previous: lastPosition!,
        received: entry.position,
      );
    }

    var nextId = id;
    final nextMethods = List<CashMethodRevision>.of(methodRevisions);
    final nextTransfers = List<ProjectedCashWalletTransfer>.of(walletTransfers);
    if (entry.event.target.kind == EntityKind.cashHandling) {
      if (nextId != null && nextId != entry.event.target.id) {
        throw const ProjectionConflictException(
          'The journal contains multiple cash handling entities.',
        );
      }
      nextId ??= entry.event.target.id;
      switch (entry.event.payload) {
        case CashHandlingMethodSetPayload(:final method):
          if (nextMethods.isNotEmpty &&
              entry.event.businessDate.isBefore(
                nextMethods.last.effectiveFrom,
              )) {
            throw const ProjectionConflictException(
              'Cash handling effective dates cannot move backwards.',
            );
          }
          nextMethods.add(
            CashMethodRevision(
              method: method,
              effectiveFrom: entry.event.businessDate,
              eventId: entry.event.id,
              recordedAtUtc: entry.event.recordedAtUtc,
            ),
          );
        case CashWalletTransferRecordedPayload(:final amount, :final label):
          if (_methodOn(nextMethods, entry.event.businessDate) !=
              CashWithdrawalMethod.cashWallet) {
            throw const ProjectionConflictException(
              'A cash-wallet transfer requires the cash-wallet method.',
            );
          }
          nextTransfers.add(
            ProjectedCashWalletTransfer._(
              eventId: entry.event.id,
              amount: amount,
              label: label,
              businessDate: entry.event.businessDate,
              recordedAtUtc: entry.event.recordedAtUtc,
            ),
          );
        case CashWalletTransferReversedPayload(:final transferEventId):
          final index = nextTransfers.indexWhere(
            (transfer) => transfer.eventId == transferEventId,
          );
          if (index < 0 || nextTransfers[index].isReversed) {
            throw ProjectionConflictException(
              'Cash-wallet transfer $transferEventId cannot be reversed.',
            );
          }
          nextTransfers[index] = nextTransfers[index]._reversedBy(entry.event);
        default:
          throw UnsupportedEventException(entry.event.eventType);
      }
    }

    return CashLedger._(
      id: nextId,
      methodRevisions: nextMethods,
      walletTransfers: nextTransfers,
      appliedEventIds: {..._appliedEventIds, entry.event.id},
      lastPosition: entry.position,
    );
  }
}

CashWithdrawalMethod? _methodOn(
  List<CashMethodRevision> revisions,
  LocalDate date,
) {
  CashMethodRevision? effective;
  for (final revision in revisions) {
    if (!revision.effectiveFrom.isAfter(date)) effective = revision;
  }
  return effective?.method;
}
