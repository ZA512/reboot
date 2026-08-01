import 'package:reboot_domain/reboot_domain.dart';

import 'projection_errors.dart';

/// Direction of one movement inside a reserve.
enum ReserveMovementKind {
  /// Money assigned to the reserve without becoming income.
  funding,

  /// Real expense financed by the reserve, outside the weekly budget.
  expense,
}

/// Immutable projected reserve movement and any later correction.
final class ProjectedReserveMovement {
  const ProjectedReserveMovement._({
    required this.eventId,
    required this.kind,
    required this.amount,
    required this.label,
    required this.businessDate,
    required this.recordedAtUtc,
    this.reversalEventId,
    this.reversedAtUtc,
  });

  factory ProjectedReserveMovement._fromEvent(
    EventRecord event,
    ReserveMovementKind kind,
    Money amount,
    String label,
  ) => ProjectedReserveMovement._(
    eventId: event.id,
    kind: kind,
    amount: amount,
    label: label,
    businessDate: event.businessDate,
    recordedAtUtc: event.recordedAtUtc,
  );

  /// Identity of the immutable funding or expense event.
  final EventId eventId;

  /// Credit or expense.
  final ReserveMovementKind kind;

  /// Positive exact movement amount.
  final Money amount;

  /// User-visible explanation.
  final String label;

  /// Civil date on which the movement occurred.
  final LocalDate businessDate;

  /// UTC journal recording instant.
  final DateTime recordedAtUtc;

  /// Correction event, if this movement was entered in error.
  final EventId? reversalEventId;

  /// UTC instant of the correction.
  final DateTime? reversedAtUtc;

  /// Whether this movement no longer contributes to the balance.
  bool get isReversed => reversalEventId != null;

  ProjectedReserveMovement _reversedBy(EventRecord event) =>
      ProjectedReserveMovement._(
        eventId: eventId,
        kind: kind,
        amount: amount,
        label: label,
        businessDate: businessDate,
        recordedAtUtc: recordedAtUtc,
        reversalEventId: event.id,
        reversedAtUtc: event.recordedAtUtc,
      );
}

/// Immutable projection of one named real or virtual reserve.
final class ProjectedReserve {
  ProjectedReserve._({
    required this.id,
    required this.name,
    required this.kind,
    required this.openingBalance,
    required List<ProjectedReserveMovement> movements,
    required this.createdAtUtc,
    required this.creationEventId,
  }) : movements = List<ProjectedReserveMovement>.unmodifiable(movements);

  factory ProjectedReserve._created(EventRecord event) {
    final payload = event.payload as ReserveCreatedPayload;
    return ProjectedReserve._(
      id: event.target.id,
      name: payload.name,
      kind: payload.kind,
      openingBalance: payload.openingBalance,
      movements: const [],
      createdAtUtc: event.recordedAtUtc,
      creationEventId: event.id,
    );
  }

  /// Stable reserve identity.
  final EntityId id;

  /// User-visible name.
  final String name;

  /// Separate bank account or internal allocation.
  final ReserveKind kind;

  /// Declared balance when this reserve started being tracked.
  final Money openingBalance;

  /// Complete movement history, including reversed mistakes.
  final List<ProjectedReserveMovement> movements;

  /// UTC instant at which tracking started.
  final DateTime createdAtUtc;

  /// Immutable reserve creation event.
  final EventId creationEventId;

  /// Active balance derived entirely from the journal.
  Money get balance {
    var result = openingBalance;
    for (final movement in movements.where((item) => !item.isReversed)) {
      result = switch (movement.kind) {
        ReserveMovementKind.funding => result + movement.amount,
        ReserveMovementKind.expense => result - movement.amount,
      };
    }
    return result;
  }

  /// Non-reversed movements in journal order.
  Iterable<ProjectedReserveMovement> get activeMovements =>
      movements.where((movement) => !movement.isReversed);

  ProjectedReserve _withMovement(ProjectedReserveMovement movement) =>
      ProjectedReserve._(
        id: id,
        name: name,
        kind: kind,
        openingBalance: openingBalance,
        movements: [...movements, movement],
        createdAtUtc: createdAtUtc,
        creationEventId: creationEventId,
      );

  ProjectedReserve _reverseMovement(EventRecord event, EventId movementId) {
    final index = movements.indexWhere((item) => item.eventId == movementId);
    if (index < 0) {
      throw ProjectionConflictException(
        'Reserve $id does not contain movement $movementId.',
      );
    }
    final movement = movements[index];
    if (movement.isReversed) {
      throw ProjectionConflictException(
        'Reserve movement $movementId received multiple reversals.',
      );
    }
    if (movement.kind == ReserveMovementKind.funding &&
        balance.compareTo(movement.amount) < 0) {
      throw InsufficientReserveBalanceException(
        reserveId: id,
        available: balance,
        requested: movement.amount,
      );
    }
    final next = List<ProjectedReserveMovement>.of(movements);
    next[index] = movement._reversedBy(event);
    return ProjectedReserve._(
      id: id,
      name: name,
      kind: kind,
      openingBalance: openingBalance,
      movements: next,
      createdAtUtc: createdAtUtc,
      creationEventId: creationEventId,
    );
  }
}

/// Replayed projection of every local reserve.
final class ReserveLedger {
  ReserveLedger._({
    required Map<EntityId, ProjectedReserve> reserves,
    required Set<EventId> appliedEventIds,
    required this.lastPosition,
  }) : reserves = Map<EntityId, ProjectedReserve>.unmodifiable(reserves),
       _appliedEventIds = Set<EventId>.unmodifiable(appliedEventIds);

  /// Creates an empty projection.
  factory ReserveLedger.empty() => ReserveLedger._(
    reserves: const {},
    appliedEventIds: const {},
    lastPosition: null,
  );

  /// Reconstructs every reserve solely from the ordered journal.
  factory ReserveLedger.replay(Iterable<LocalJournalEntry> entries) => entries
      .fold(ReserveLedger.empty(), (ledger, entry) => ledger.apply(entry));

  /// All named reserves.
  final Map<EntityId, ProjectedReserve> reserves;

  final Set<EventId> _appliedEventIds;

  /// Last non-duplicate global journal position applied.
  final LocalJournalPosition? lastPosition;

  /// Combined declared balance of all reserves.
  Money get totalBalance => reserves.values.fold(
    Money.zero(Currency.eur),
    (sum, reserve) => sum + reserve.balance,
  );

  /// Applies one ordered journal entry immutably.
  ReserveLedger apply(LocalJournalEntry entry) {
    if (_appliedEventIds.contains(entry.event.id)) return this;
    if (lastPosition != null && entry.position.compareTo(lastPosition!) <= 0) {
      throw LocalJournalOrderException(
        previous: lastPosition!,
        received: entry.position,
      );
    }
    final next = Map<EntityId, ProjectedReserve>.of(reserves);
    if (entry.event.target.kind == EntityKind.reserve) {
      final reserveId = entry.event.target.id;
      switch (entry.event.payload) {
        case ReserveCreatedPayload():
          if (next.containsKey(reserveId)) {
            throw ProjectionConflictException(
              'Reserve $reserveId was created more than once.',
            );
          }
          next[reserveId] = ProjectedReserve._created(entry.event);
        case ReserveFundsAddedPayload(:final amount, :final label):
          final reserve = _requireReserve(next, reserveId);
          next[reserveId] = reserve._withMovement(
            ProjectedReserveMovement._fromEvent(
              entry.event,
              ReserveMovementKind.funding,
              amount,
              label,
            ),
          );
        case ReserveExpenseRecordedPayload(:final amount, :final label):
          final reserve = _requireReserve(next, reserveId);
          if (reserve.balance.compareTo(amount) < 0) {
            throw InsufficientReserveBalanceException(
              reserveId: reserveId,
              available: reserve.balance,
              requested: amount,
            );
          }
          next[reserveId] = reserve._withMovement(
            ProjectedReserveMovement._fromEvent(
              entry.event,
              ReserveMovementKind.expense,
              amount,
              label,
            ),
          );
        case ReserveMovementReversedPayload(:final movementEventId):
          next[reserveId] = _requireReserve(
            next,
            reserveId,
          )._reverseMovement(entry.event, movementEventId);
        default:
          throw UnsupportedEventException(entry.event.eventType);
      }
    }
    return ReserveLedger._(
      reserves: next,
      appliedEventIds: {..._appliedEventIds, entry.event.id},
      lastPosition: entry.position,
    );
  }
}

ProjectedReserve _requireReserve(
  Map<EntityId, ProjectedReserve> reserves,
  EntityId reserveId,
) {
  final reserve = reserves[reserveId];
  if (reserve == null) {
    throw ProjectionConflictException(
      'Reserve $reserveId received a movement before creation.',
    );
  }
  return reserve;
}

/// A declared reserve cannot finance more than its projected balance.
final class InsufficientReserveBalanceException implements Exception {
  const InsufficientReserveBalanceException({
    required this.reserveId,
    required this.available,
    required this.requested,
  });

  final EntityId reserveId;
  final Money available;
  final Money requested;

  @override
  String toString() =>
      'InsufficientReserveBalanceException: reserve $reserveId has '
      '$available but $requested was requested.';
}
