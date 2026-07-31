import 'dart:convert';

import 'package:reboot_domain/reboot_domain.dart';

/// Version-aware canonical JSON codec for immutable event payloads.
final class EventPayloadJsonCodec {
  /// Encodes only the payload; event metadata lives in dedicated SQL columns.
  String encode(EventPayload payload) {
    final value = switch (payload) {
      HouseholdCreatedPayload() => <String, Object?>{
        'householdKind': payload.householdKind.name,
        'currency': payload.currency.code,
        'initialCyclePolicy': _encodeCyclePolicy(payload.initialCyclePolicy),
      },
      HouseholdCyclePolicyChangedPayload() => <String, Object?>{
        'nextPolicy': _encodeCyclePolicy(payload.nextPolicy),
      },
      CashFlowCreatedPayload() => <String, Object?>{
        'definition': _encodeCashFlow(payload.definition),
        'effectiveFromCycleStart': payload.effectiveFromCycleStart.toString(),
      },
      CashFlowReplacedPayload() => <String, Object?>{
        'definition': _encodeCashFlow(payload.definition),
        'effectiveFromCycleStart': payload.effectiveFromCycleStart.toString(),
      },
      CashFlowDeletedPayload() => <String, Object?>{
        'effectiveFromCycleStart': payload.effectiveFromCycleStart.toString(),
      },
      AnnualCommitmentsSetPayload() => <String, Object?>{
        'effectiveFromCycleStart': payload.effectiveFromCycleStart.toString(),
        'reserveContributions': _encodeMoney(payload.reserveContributions),
        'projectContributions': _encodeMoney(payload.projectContributions),
        'safetyMargin': _encodeMoney(payload.safetyMargin),
      },
      TrajectoryPlanSetPayload() => <String, Object?>{
        'effectiveFromCycleStart': payload.effectiveFromCycleStart.toString(),
        'strategy': payload.strategy.name,
        'reserveContributions': _encodeMoney(payload.reserveContributions),
        'projectContributions': _encodeMoney(payload.projectContributions),
        'safetyMargin': _encodeMoney(payload.safetyMargin),
        'overdraftExitGoal': switch (payload.overdraftExitGoal) {
          final goal? => <String, Object?>{
            'currentOverdraftDepth': _encodeMoney(goal.currentOverdraftDepth),
            'targetCushion': _encodeMoney(goal.targetCushion),
            'targetDate': goal.targetDate.toString(),
          },
          null => null,
        },
      },
      ExpenseRecordedPayload() => <String, Object?>{
        'amount': _encodeMoney(payload.amount),
        'label': payload.label,
        'cycleAssignment': <String, Object?>{
          'cycleStart': payload.cycleAssignment.cycleStart.toString(),
          'policyVersion': payload.cycleAssignment.policyVersion,
          'timeZone': payload.cycleAssignment.timeZone.value,
        },
      },
      ExpenseAllocationsPlannedPayload() => <String, Object?>{
        'allocations': [
          for (final allocation in payload.allocations)
            <String, Object?>{
              'cycleStart': allocation.cycleStart.toString(),
              'amount': _encodeMoney(allocation.amount),
            },
        ],
      },
      ExpenseDeletedPayload() => const <String, Object?>{},
      ExpenseRefundedPayload() => <String, Object?>{
        'amount': _encodeMoney(payload.amount),
        'receiptCycleStart': payload.receiptCycleStart.toString(),
      },
      ExpenseRefundReversedPayload() => <String, Object?>{
        'refundEventId': payload.refundEventId.value,
      },
      ReserveCreatedPayload() => <String, Object?>{
        'name': payload.name,
        'kind': payload.kind.name,
        'openingBalance': _encodeMoney(payload.openingBalance),
      },
      ReserveFundsAddedPayload() => <String, Object?>{
        'amount': _encodeMoney(payload.amount),
        'label': payload.label,
      },
      ReserveExpenseRecordedPayload() => <String, Object?>{
        'amount': _encodeMoney(payload.amount),
        'label': payload.label,
      },
      ReserveMovementReversedPayload() => <String, Object?>{
        'movementEventId': payload.movementEventId.value,
      },
      HealthTrackingConfiguredPayload() => <String, Object?>{
        'enabled': payload.enabled,
        'delayWeeks': payload.delayWeeks,
        'alertThreshold': _encodeMoney(payload.alertThreshold),
      },
      HealthExpenseRecordedPayload() => <String, Object?>{
        'amount': _encodeMoney(payload.amount),
        'label': payload.label,
      },
      HealthReimbursementRecordedPayload() => <String, Object?>{
        'amount': _encodeMoney(payload.amount),
        'label': payload.label,
      },
      HealthRegularizationRecordedPayload() => <String, Object?>{
        'amount': _encodeMoney(payload.amount),
        'label': payload.label,
      },
      HealthEntryReversedPayload() => <String, Object?>{
        'entryEventId': payload.entryEventId.value,
      },
      _ => throw UnsupportedStoredEventException(
        payload.eventType,
        payload.schemaVersion,
      ),
    };
    return jsonEncode(value);
  }

  /// Decodes one supported payload schema.
  EventPayload decode({
    required String eventType,
    required int schemaVersion,
    required String json,
  }) {
    if (schemaVersion != 1) {
      throw UnsupportedStoredEventException(eventType, schemaVersion);
    }
    final Object? decoded = jsonDecode(json);
    final map = _asMap(decoded, 'payload');
    return switch (eventType) {
      'household.created' => HouseholdCreatedPayload(
        householdKind: _enumByName(
          HouseholdKind.values,
          _asString(map['householdKind'], 'householdKind'),
        ),
        currency: Currency.parse(_asString(map['currency'], 'currency')),
        initialCyclePolicy: _decodeCyclePolicy(
          _asMap(map['initialCyclePolicy'], 'initialCyclePolicy'),
        ),
      ),
      'household.cycle-policy.changed' => HouseholdCyclePolicyChangedPayload(
        nextPolicy: _decodeCyclePolicy(_asMap(map['nextPolicy'], 'nextPolicy')),
      ),
      'cash-flow.created' => CashFlowCreatedPayload(
        definition: _decodeCashFlow(_asMap(map['definition'], 'definition')),
        effectiveFromCycleStart: _decodeDate(
          map['effectiveFromCycleStart'],
          'effectiveFromCycleStart',
        ),
      ),
      'cash-flow.replaced' => CashFlowReplacedPayload(
        definition: _decodeCashFlow(_asMap(map['definition'], 'definition')),
        effectiveFromCycleStart: _decodeDate(
          map['effectiveFromCycleStart'],
          'effectiveFromCycleStart',
        ),
      ),
      'cash-flow.deleted' => CashFlowDeletedPayload(
        effectiveFromCycleStart: _decodeDate(
          map['effectiveFromCycleStart'],
          'effectiveFromCycleStart',
        ),
      ),
      'annual-commitments.set' => AnnualCommitmentsSetPayload(
        effectiveFromCycleStart: _decodeDate(
          map['effectiveFromCycleStart'],
          'effectiveFromCycleStart',
        ),
        reserveContributions: _decodeMoney(
          _asMap(map['reserveContributions'], 'reserveContributions'),
        ),
        projectContributions: _decodeMoney(
          _asMap(map['projectContributions'], 'projectContributions'),
        ),
        safetyMargin: _decodeMoney(_asMap(map['safetyMargin'], 'safetyMargin')),
      ),
      'trajectory-plan.set' => TrajectoryPlanSetPayload(
        effectiveFromCycleStart: _decodeDate(
          map['effectiveFromCycleStart'],
          'effectiveFromCycleStart',
        ),
        strategy: _enumByName(
          TrajectoryStrategy.values,
          _asString(map['strategy'], 'strategy'),
        ),
        reserveContributions: _decodeMoney(
          _asMap(map['reserveContributions'], 'reserveContributions'),
        ),
        projectContributions: _decodeMoney(
          _asMap(map['projectContributions'], 'projectContributions'),
        ),
        safetyMargin: _decodeMoney(_asMap(map['safetyMargin'], 'safetyMargin')),
        overdraftExitGoal: switch (map['overdraftExitGoal']) {
          final value? => _decodeOverdraftExitGoal(
            _asMap(value, 'overdraftExitGoal'),
          ),
          null => null,
        },
      ),
      'expense.recorded' => _decodeExpenseRecorded(map),
      'expense.allocations.planned' => _decodeExpenseAllocations(map),
      'expense.deleted' => const ExpenseDeletedPayload(),
      'expense.refunded' => ExpenseRefundedPayload(
        amount: _decodeMoney(_asMap(map['amount'], 'amount')),
        receiptCycleStart: _decodeDate(
          map['receiptCycleStart'],
          'receiptCycleStart',
        ),
      ),
      'expense.refund-reversed' => ExpenseRefundReversedPayload(
        refundEventId: EventId(
          _asString(map['refundEventId'], 'refundEventId'),
        ),
      ),
      'reserve.created' => ReserveCreatedPayload(
        name: _asString(map['name'], 'name'),
        kind: _enumByName(ReserveKind.values, _asString(map['kind'], 'kind')),
        openingBalance: _decodeMoney(
          _asMap(map['openingBalance'], 'openingBalance'),
        ),
      ),
      'reserve.funds-added' => ReserveFundsAddedPayload(
        amount: _decodeMoney(_asMap(map['amount'], 'amount')),
        label: _asString(map['label'], 'label'),
      ),
      'reserve.expense-recorded' => ReserveExpenseRecordedPayload(
        amount: _decodeMoney(_asMap(map['amount'], 'amount')),
        label: _asString(map['label'], 'label'),
      ),
      'reserve.movement-reversed' => ReserveMovementReversedPayload(
        movementEventId: EventId(
          _asString(map['movementEventId'], 'movementEventId'),
        ),
      ),
      'health-tracking.configured' => HealthTrackingConfiguredPayload(
        enabled: _asBool(map['enabled'], 'enabled'),
        delayWeeks: _asInt(map['delayWeeks'], 'delayWeeks'),
        alertThreshold: _decodeMoney(
          _asMap(map['alertThreshold'], 'alertThreshold'),
        ),
      ),
      'health.expense-recorded' => HealthExpenseRecordedPayload(
        amount: _decodeMoney(_asMap(map['amount'], 'amount')),
        label: _asString(map['label'], 'label'),
      ),
      'health.reimbursement-recorded' => HealthReimbursementRecordedPayload(
        amount: _decodeMoney(_asMap(map['amount'], 'amount')),
        label: _asString(map['label'], 'label'),
      ),
      'health.regularization-recorded' => HealthRegularizationRecordedPayload(
        amount: _decodeMoney(_asMap(map['amount'], 'amount')),
        label: _asString(map['label'], 'label'),
      ),
      'health.entry-reversed' => HealthEntryReversedPayload(
        entryEventId: EventId(_asString(map['entryEventId'], 'entryEventId')),
      ),
      _ => throw UnsupportedStoredEventException(eventType, schemaVersion),
    };
  }
}

OverdraftExitGoal _decodeOverdraftExitGoal(Map<String, Object?> map) {
  return OverdraftExitGoal(
    currentOverdraftDepth: _decodeMoney(
      _asMap(map['currentOverdraftDepth'], 'currentOverdraftDepth'),
    ),
    targetCushion: _decodeMoney(_asMap(map['targetCushion'], 'targetCushion')),
    targetDate: _decodeDate(map['targetDate'], 'targetDate'),
  );
}

Map<String, Object?> _encodeCyclePolicy(CyclePolicy policy) {
  return <String, Object?>{
    'version': policy.version,
    'effectiveFrom': policy.effectiveFrom.toString(),
    'anchorWeekday': policy.anchorWeekday.name,
    'timeZone': policy.timeZone.value,
  };
}

CyclePolicy _decodeCyclePolicy(Map<String, Object?> map) {
  return CyclePolicy(
    version: _asInt(map['version'], 'version'),
    effectiveFrom: _decodeDate(map['effectiveFrom'], 'effectiveFrom'),
    anchorWeekday: _enumByName(
      Weekday.values,
      _asString(map['anchorWeekday'], 'anchorWeekday'),
    ),
    timeZone: IanaTimeZoneId(_asString(map['timeZone'], 'timeZone')),
  );
}

Map<String, Object?> _encodeCashFlow(CashFlowDefinition definition) {
  return <String, Object?>{
    'title': definition.title,
    'direction': definition.direction.name,
    'behavior': definition.behavior.name,
    'schedule': _encodeSchedule(definition.schedule),
    'referenceAmountPerOccurrence': _encodeMoney(
      definition.referenceAmountPerOccurrence,
    ),
    'variableStrategy': definition.variableStrategy?.name,
    'customAmountPerOccurrence': switch (definition.customAmountPerOccurrence) {
      final amount? => _encodeMoney(amount),
      null => null,
    },
    'lastConfirmedOn': definition.lastConfirmedOn?.toString(),
  };
}

CashFlowDefinition _decodeCashFlow(Map<String, Object?> map) {
  final title = _asString(map['title'], 'title');
  final direction = _enumByName(
    CashFlowDirection.values,
    _asString(map['direction'], 'direction'),
  );
  final behavior = _enumByName(
    AmountBehavior.values,
    _asString(map['behavior'], 'behavior'),
  );
  final schedule = _decodeSchedule(_asMap(map['schedule'], 'schedule'));
  final reference = _decodeMoney(
    _asMap(map['referenceAmountPerOccurrence'], 'referenceAmountPerOccurrence'),
  );
  final confirmed = _decodeNullableDate(map['lastConfirmedOn']);

  return switch (behavior) {
    AmountBehavior.fixed => CashFlowDefinition.fixed(
      title: title,
      direction: direction,
      schedule: schedule,
      amountPerOccurrence: reference,
      lastConfirmedOn: confirmed,
    ),
    AmountBehavior.variable => CashFlowDefinition.variable(
      title: title,
      direction: direction,
      schedule: schedule,
      historicalAveragePerOccurrence: reference,
      strategy: _enumByName(
        VariableEstimateStrategy.values,
        _asString(map['variableStrategy'], 'variableStrategy'),
      ),
      customAmountPerOccurrence: switch (map['customAmountPerOccurrence']) {
        final value? => _decodeMoney(
          _asMap(value, 'customAmountPerOccurrence'),
        ),
        null => null,
      },
      lastConfirmedOn: confirmed,
    ),
  };
}

Map<String, Object?> _encodeSchedule(OccurrenceSchedule schedule) {
  return switch (schedule) {
    RecurringSchedule() => <String, Object?>{
      'type': 'recurring',
      'firstOccurrence': schedule.firstOccurrence.toString(),
      'frequency': schedule.frequency.name,
      'lastOccurrence': schedule.lastOccurrence?.toString(),
    },
    CustomDateSchedule() => <String, Object?>{
      'type': 'customDates',
      'dates': [for (final date in schedule.dates) date.toString()],
    },
  };
}

OccurrenceSchedule _decodeSchedule(Map<String, Object?> map) {
  return switch (_asString(map['type'], 'schedule.type')) {
    'recurring' => RecurringSchedule(
      firstOccurrence: _decodeDate(map['firstOccurrence'], 'firstOccurrence'),
      frequency: _enumByName(
        RecurrenceFrequency.values,
        _asString(map['frequency'], 'frequency'),
      ),
      lastOccurrence: _decodeNullableDate(map['lastOccurrence']),
    ),
    'customDates' => CustomDateSchedule(
      _asList(
        map['dates'],
        'dates',
      ).map((value) => _decodeDate(value, 'dates[]')),
    ),
    final type => throw FormatException('Unsupported schedule type: $type'),
  };
}

Map<String, Object?> _encodeMoney(Money money) {
  return <String, Object?>{
    'minorUnits': money.minorUnits,
    'currency': money.currency.code,
  };
}

Money _decodeMoney(Map<String, Object?> map) {
  return Money.fromMinorUnits(
    _asInt(map['minorUnits'], 'minorUnits'),
    Currency.parse(_asString(map['currency'], 'currency')),
  );
}

ExpenseRecordedPayload _decodeExpenseRecorded(Map<String, Object?> map) {
  final assignment = _asMap(map['cycleAssignment'], 'cycleAssignment');
  return ExpenseRecordedPayload(
    amount: _decodeMoney(_asMap(map['amount'], 'amount')),
    label: _asString(map['label'], 'label'),
    cycleAssignment: ExpenseCycleAssignment(
      cycleStart: _decodeDate(assignment['cycleStart'], 'cycleStart'),
      policyVersion: _asInt(assignment['policyVersion'], 'policyVersion'),
      timeZone: IanaTimeZoneId(_asString(assignment['timeZone'], 'timeZone')),
    ),
  );
}

ExpenseAllocationsPlannedPayload _decodeExpenseAllocations(
  Map<String, Object?> map,
) {
  return ExpenseAllocationsPlannedPayload(
    allocations: [
      for (final value in _asList(map['allocations'], 'allocations'))
        _decodeExpenseAllocation(_asMap(value, 'allocations[]')),
    ],
  );
}

ExpenseAllocation _decodeExpenseAllocation(Map<String, Object?> map) {
  return ExpenseAllocation(
    cycleStart: _decodeDate(map['cycleStart'], 'cycleStart'),
    amount: _decodeMoney(_asMap(map['amount'], 'amount')),
  );
}

LocalDate _decodeDate(Object? value, String name) {
  final parts = _asString(value, name).split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid stored date in $name.');
  }
  return LocalDate(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

LocalDate? _decodeNullableDate(Object? value) {
  return value == null ? null : _decodeDate(value, 'date');
}

Map<String, Object?> _asMap(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw FormatException('Stored $name must be an object.');
  }
  return value;
}

List<Object?> _asList(Object? value, String name) {
  if (value is! List<Object?>) {
    throw FormatException('Stored $name must be a list.');
  }
  return value;
}

String _asString(Object? value, String name) {
  if (value is! String) {
    throw FormatException('Stored $name must be a string.');
  }
  return value;
}

int _asInt(Object? value, String name) {
  if (value is! int) {
    throw FormatException('Stored $name must be an integer.');
  }
  return value;
}

bool _asBool(Object? value, String name) {
  if (value is! bool) {
    throw FormatException('Stored $name must be a boolean.');
  }
  return value;
}

T _enumByName<T extends Enum>(List<T> values, String name) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  throw FormatException('Unsupported stored enum value: $name');
}

/// A stored event type or schema version this application cannot safely read.
final class UnsupportedStoredEventException implements Exception {
  /// Creates an unsupported stored payload error.
  const UnsupportedStoredEventException(this.eventType, this.schemaVersion);

  /// Stable payload type.
  final String eventType;

  /// Unsupported version.
  final int schemaVersion;

  @override
  String toString() {
    return 'UnsupportedStoredEventException: $eventType v$schemaVersion';
  }
}
