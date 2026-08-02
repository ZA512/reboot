import 'dart:convert';

import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

/// Canonical, cross-platform codec for the derived expense projection.
///
/// This checkpoint is disposable and never replaces the immutable journal.
/// Exact integers are encoded as decimal strings so JavaScript and native
/// runtimes produce identical bytes.
final class ExpenseLedgerSnapshotCodec {
  static const int schemaVersion = 1;
  static const int maximumEncodedBytes = 8 * 1024 * 1024;
  static const String _recordKind = 'reboot-expense-ledger';

  static const Set<String> _rootFields = {
    'recordKind',
    'schemaVersion',
    'lastPosition',
    'expenses',
  };
  static const Set<String> _expenseFields = {
    'id',
    'amount',
    'label',
    'purchaseDate',
    'cycleAssignment',
    'recordedAtUtcMicros',
    'recordingEventId',
    'nature',
    'natureEventId',
    'refunds',
    'allocations',
    'allocationEventId',
    'deletedAtUtcMicros',
    'deletionEventId',
  };
  static const Set<String> _cycleAssignmentFields = {
    'cycleStart',
    'policyVersion',
    'timeZone',
  };
  static const Set<String> _refundFields = {
    'eventId',
    'amount',
    'receivedDate',
    'receiptCycleStart',
    'recordedAtUtcMicros',
    'reversalEventId',
  };
  static const Set<String> _allocationFields = {'cycleStart', 'amount'};
  static const Set<String> _moneyFields = {'minorUnits', 'currency'};
  static final BigInt _maximumSafeTimestamp = BigInt.parse('9007199254740991');

  String encode(ExpenseLedger ledger) {
    final position = ledger.lastPosition;
    if (position == null) {
      throw const FormatException(
        'An expense checkpoint requires a positive journal position.',
      );
    }
    final expenses = ledger.expenses.values.toList(growable: false)
      ..sort((left, right) => left.id.value.compareTo(right.id.value));
    final source = jsonEncode(<String, Object?>{
      'recordKind': _recordKind,
      'schemaVersion': schemaVersion,
      'lastPosition': position.exactValue.toString(),
      'expenses': [for (final expense in expenses) _encodeExpense(expense)],
    });
    if (utf8.encode(source).length > maximumEncodedBytes) {
      throw const FormatException('The expense checkpoint is too large.');
    }
    return source;
  }

  ExpenseLedger decode(String source) {
    if (utf8.encode(source).length > maximumEncodedBytes) {
      throw const FormatException('The expense checkpoint is too large.');
    }
    try {
      final root = _map(jsonDecode(source), 'expense checkpoint');
      _requireFields(root, _rootFields, 'expense checkpoint');
      if (_string(root, 'recordKind') != _recordKind ||
          _integer(root, 'schemaVersion') != schemaVersion) {
        throw const FormatException('Unsupported expense checkpoint format.');
      }
      final expenses = <ProjectedExpense>[
        for (final value in _list(root, 'expenses'))
          _decodeExpense(_map(value, 'expense')),
      ];
      final ledger = ExpenseLedger.fromCheckpoint(
        expenses: expenses,
        lastPosition: LocalJournalPosition.fromBigInt(
          _canonicalBigInt(_string(root, 'lastPosition'), 'lastPosition'),
        ),
      );
      if (encode(ledger) != source) {
        throw const FormatException('The expense checkpoint is not canonical.');
      }
      return ledger;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('The expense checkpoint is invalid.');
    }
  }

  Map<String, Object?> _encodeExpense(ProjectedExpense expense) => {
    'id': expense.id.value,
    'amount': _encodeMoney(expense.amount),
    'label': expense.label,
    'purchaseDate': expense.purchaseDate.toString(),
    'cycleAssignment': <String, Object?>{
      'cycleStart': expense.cycleAssignment.cycleStart.toString(),
      'policyVersion': expense.cycleAssignment.policyVersion,
      'timeZone': expense.cycleAssignment.timeZone.value,
    },
    'recordedAtUtcMicros': _encodeTimestamp(expense.recordedAtUtc),
    'recordingEventId': expense.recordingEventId.value,
    'nature': expense.nature?.name,
    'natureEventId': expense.natureEventId?.value,
    'refunds': [for (final refund in expense.refunds) _encodeRefund(refund)],
    'allocations': switch (expense.allocations) {
      final allocations? => [
        for (final allocation in allocations)
          <String, Object?>{
            'cycleStart': allocation.cycleStart.toString(),
            'amount': _encodeMoney(allocation.amount),
          },
      ],
      null => null,
    },
    'allocationEventId': expense.allocationEventId?.value,
    'deletedAtUtcMicros': switch (expense.deletedAtUtc) {
      final timestamp? => _encodeTimestamp(timestamp),
      null => null,
    },
    'deletionEventId': expense.deletionEventId?.value,
  };

  ProjectedExpense _decodeExpense(Map<String, Object?> map) {
    _requireFields(map, _expenseFields, 'expense');
    final assignment = _map(map['cycleAssignment'], 'cycleAssignment');
    _requireFields(assignment, _cycleAssignmentFields, 'cycleAssignment');
    final allocationsValue = map['allocations'];
    return ProjectedExpense.fromCheckpoint(
      id: EntityId(_string(map, 'id')),
      amount: _decodeMoney(_map(map['amount'], 'amount')),
      label: _string(map, 'label'),
      purchaseDate: _date(_string(map, 'purchaseDate'), 'purchaseDate'),
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: _date(
          _string(assignment, 'cycleStart'),
          'cycleAssignment.cycleStart',
        ),
        policyVersion: _integer(assignment, 'policyVersion'),
        timeZone: IanaTimeZoneId(_string(assignment, 'timeZone')),
      ),
      recordedAtUtc: _timestamp(
        _string(map, 'recordedAtUtcMicros'),
        'recordedAtUtcMicros',
      ),
      recordingEventId: EventId(_string(map, 'recordingEventId')),
      nature: _nullableEnum(ExpenseNature.values, map['nature'], 'nature'),
      natureEventId: _nullableEventId(map['natureEventId'], 'natureEventId'),
      refunds: [
        for (final value in _list(map, 'refunds'))
          _decodeRefund(_map(value, 'refund')),
      ],
      allocations: allocationsValue == null
          ? null
          : [
              for (final value in _asList(allocationsValue, 'allocations'))
                _decodeAllocation(_map(value, 'allocation')),
            ],
      allocationEventId: _nullableEventId(
        map['allocationEventId'],
        'allocationEventId',
      ),
      deletedAtUtc: _nullableTimestamp(
        map['deletedAtUtcMicros'],
        'deletedAtUtcMicros',
      ),
      deletionEventId: _nullableEventId(
        map['deletionEventId'],
        'deletionEventId',
      ),
    );
  }

  Map<String, Object?> _encodeRefund(ProjectedExpenseRefund refund) => {
    'eventId': refund.eventId.value,
    'amount': _encodeMoney(refund.amount),
    'receivedDate': refund.receivedDate.toString(),
    'receiptCycleStart': refund.receiptCycleStart.toString(),
    'recordedAtUtcMicros': _encodeTimestamp(refund.recordedAtUtc),
    'reversalEventId': refund.reversalEventId?.value,
  };

  ProjectedExpenseRefund _decodeRefund(Map<String, Object?> map) {
    _requireFields(map, _refundFields, 'refund');
    return ProjectedExpenseRefund.fromCheckpoint(
      eventId: EventId(_string(map, 'eventId')),
      amount: _decodeMoney(_map(map['amount'], 'amount')),
      receivedDate: _date(_string(map, 'receivedDate'), 'receivedDate'),
      receiptCycleStart: _date(
        _string(map, 'receiptCycleStart'),
        'receiptCycleStart',
      ),
      recordedAtUtc: _timestamp(
        _string(map, 'recordedAtUtcMicros'),
        'refund.recordedAtUtcMicros',
      ),
      reversalEventId: _nullableEventId(
        map['reversalEventId'],
        'reversalEventId',
      ),
    );
  }

  ExpenseAllocation _decodeAllocation(Map<String, Object?> map) {
    _requireFields(map, _allocationFields, 'allocation');
    return ExpenseAllocation(
      cycleStart: _date(_string(map, 'cycleStart'), 'allocation.cycleStart'),
      amount: _decodeMoney(_map(map['amount'], 'allocation.amount')),
    );
  }

  Map<String, Object?> _encodeMoney(Money money) => {
    'minorUnits': money.exactMinorUnits.toString(),
    'currency': money.currency.code,
  };

  Money _decodeMoney(Map<String, Object?> map) {
    _requireFields(map, _moneyFields, 'money');
    return Money.fromMinorUnitsDecimal(
      _string(map, 'minorUnits'),
      Currency.parse(_string(map, 'currency')),
    );
  }

  String _encodeTimestamp(DateTime value) {
    if (!value.isUtc) {
      throw const FormatException('Checkpoint timestamps must be UTC.');
    }
    final micros = BigInt.from(value.microsecondsSinceEpoch);
    if (micros.abs() > _maximumSafeTimestamp) {
      throw const FormatException(
        'Checkpoint timestamps must be exactly portable to JavaScript.',
      );
    }
    return micros.toString();
  }

  DateTime _timestamp(String source, String field) {
    final micros = _canonicalBigInt(source, field);
    if (micros.abs() > _maximumSafeTimestamp) {
      throw FormatException('$field is not exactly portable to JavaScript.');
    }
    return DateTime.fromMicrosecondsSinceEpoch(micros.toInt(), isUtc: true);
  }

  DateTime? _nullableTimestamp(Object? value, String field) {
    if (value == null) return null;
    if (value is! String) throw FormatException('$field must be a string.');
    return _timestamp(value, field);
  }
}

Map<String, Object?> _map(Object? value, String field) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$field must be an object.');
  }
  return value;
}

List<Object?> _list(Map<String, Object?> map, String field) =>
    _asList(map[field], field);

List<Object?> _asList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('$field must be an array.');
  }
  return value;
}

void _requireFields(
  Map<String, Object?> map,
  Set<String> expected,
  String field,
) {
  if (map.length != expected.length ||
      !map.keys.toSet().containsAll(expected)) {
    throw FormatException('$field contains unexpected fields.');
  }
}

String _string(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

int _integer(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! int) throw FormatException('$field must be an integer.');
  return value;
}

BigInt _canonicalBigInt(String source, String field) {
  final value = BigInt.tryParse(source);
  if (value == null || value.toString() != source) {
    throw FormatException('$field must be a canonical decimal integer.');
  }
  return value;
}

LocalDate _date(String source, String field) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(source);
  if (match == null) throw FormatException('$field must be an ISO date.');
  final date = LocalDate(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  if (date.toString() != source) {
    throw FormatException('$field must be a canonical ISO date.');
  }
  return date;
}

EventId? _nullableEventId(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) throw FormatException('$field must be a string.');
  return EventId(value);
}

T? _nullableEnum<T extends Enum>(List<T> values, Object? value, String field) {
  if (value == null) return null;
  if (value is! String) throw FormatException('$field must be a string.');
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('Unsupported $field: $value.');
}
