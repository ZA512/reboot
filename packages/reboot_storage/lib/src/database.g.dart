// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalEventsTable extends LocalEvents
    with TableInfo<$LocalEventsTable, LocalEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localPositionMeta = const VerificationMeta(
    'localPosition',
  );
  @override
  late final GeneratedColumn<int> localPosition = GeneratedColumn<int>(
    'local_position',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _recordedAtUtcMicrosMeta =
      const VerificationMeta('recordedAtUtcMicros');
  @override
  late final GeneratedColumn<int> recordedAtUtcMicros = GeneratedColumn<int>(
    'recorded_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessDateMeta = const VerificationMeta(
    'businessDate',
  );
  @override
  late final GeneratedColumn<String> businessDate = GeneratedColumn<String>(
    'business_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  @override
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventSchemaVersionMeta =
      const VerificationMeta('eventSchemaVersion');
  @override
  late final GeneratedColumn<int> eventSchemaVersion = GeneratedColumn<int>(
    'event_schema_version',
    aliasedName,
    false,
    check: () => const CustomExpression('event_schema_version > 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localPosition,
    eventId,
    recordedAtUtcMicros,
    businessDate,
    entityKind,
    entityId,
    eventType,
    eventSchemaVersion,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_position')) {
      context.handle(
        _localPositionMeta,
        localPosition.isAcceptableOrUnknown(
          data['local_position']!,
          _localPositionMeta,
        ),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('recorded_at_utc_micros')) {
      context.handle(
        _recordedAtUtcMicrosMeta,
        recordedAtUtcMicros.isAcceptableOrUnknown(
          data['recorded_at_utc_micros']!,
          _recordedAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedAtUtcMicrosMeta);
    }
    if (data.containsKey('business_date')) {
      context.handle(
        _businessDateMeta,
        businessDate.isAcceptableOrUnknown(
          data['business_date']!,
          _businessDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessDateMeta);
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('event_schema_version')) {
      context.handle(
        _eventSchemaVersionMeta,
        eventSchemaVersion.isAcceptableOrUnknown(
          data['event_schema_version']!,
          _eventSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventSchemaVersionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localPosition};
  @override
  LocalEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEvent(
      localPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_position'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      recordedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at_utc_micros'],
      )!,
      businessDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_date'],
      )!,
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      eventSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_schema_version'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $LocalEventsTable createAlias(String alias) {
    return $LocalEventsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class LocalEvent extends DataClass implements Insertable<LocalEvent> {
  /// Monotone position assigned by this local database only.
  final int localPosition;

  /// Globally stable event UUID.
  final String eventId;

  /// UTC microseconds since Unix epoch.
  final int recordedAtUtcMicros;

  /// ISO local civil business date.
  final String businessDate;

  /// Stable target entity family.
  final String entityKind;

  /// Stable target entity UUID.
  final String entityId;

  /// Stable event payload type.
  final String eventType;

  /// Positive payload schema version.
  final int eventSchemaVersion;

  /// Canonical JSON payload. The containing database page is encrypted.
  final String payloadJson;
  const LocalEvent({
    required this.localPosition,
    required this.eventId,
    required this.recordedAtUtcMicros,
    required this.businessDate,
    required this.entityKind,
    required this.entityId,
    required this.eventType,
    required this.eventSchemaVersion,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_position'] = Variable<int>(localPosition);
    map['event_id'] = Variable<String>(eventId);
    map['recorded_at_utc_micros'] = Variable<int>(recordedAtUtcMicros);
    map['business_date'] = Variable<String>(businessDate);
    map['entity_kind'] = Variable<String>(entityKind);
    map['entity_id'] = Variable<String>(entityId);
    map['event_type'] = Variable<String>(eventType);
    map['event_schema_version'] = Variable<int>(eventSchemaVersion);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  LocalEventsCompanion toCompanion(bool nullToAbsent) {
    return LocalEventsCompanion(
      localPosition: Value(localPosition),
      eventId: Value(eventId),
      recordedAtUtcMicros: Value(recordedAtUtcMicros),
      businessDate: Value(businessDate),
      entityKind: Value(entityKind),
      entityId: Value(entityId),
      eventType: Value(eventType),
      eventSchemaVersion: Value(eventSchemaVersion),
      payloadJson: Value(payloadJson),
    );
  }

  factory LocalEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEvent(
      localPosition: serializer.fromJson<int>(json['localPosition']),
      eventId: serializer.fromJson<String>(json['eventId']),
      recordedAtUtcMicros: serializer.fromJson<int>(
        json['recordedAtUtcMicros'],
      ),
      businessDate: serializer.fromJson<String>(json['businessDate']),
      entityKind: serializer.fromJson<String>(json['entityKind']),
      entityId: serializer.fromJson<String>(json['entityId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      eventSchemaVersion: serializer.fromJson<int>(json['eventSchemaVersion']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localPosition': serializer.toJson<int>(localPosition),
      'eventId': serializer.toJson<String>(eventId),
      'recordedAtUtcMicros': serializer.toJson<int>(recordedAtUtcMicros),
      'businessDate': serializer.toJson<String>(businessDate),
      'entityKind': serializer.toJson<String>(entityKind),
      'entityId': serializer.toJson<String>(entityId),
      'eventType': serializer.toJson<String>(eventType),
      'eventSchemaVersion': serializer.toJson<int>(eventSchemaVersion),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  LocalEvent copyWith({
    int? localPosition,
    String? eventId,
    int? recordedAtUtcMicros,
    String? businessDate,
    String? entityKind,
    String? entityId,
    String? eventType,
    int? eventSchemaVersion,
    String? payloadJson,
  }) => LocalEvent(
    localPosition: localPosition ?? this.localPosition,
    eventId: eventId ?? this.eventId,
    recordedAtUtcMicros: recordedAtUtcMicros ?? this.recordedAtUtcMicros,
    businessDate: businessDate ?? this.businessDate,
    entityKind: entityKind ?? this.entityKind,
    entityId: entityId ?? this.entityId,
    eventType: eventType ?? this.eventType,
    eventSchemaVersion: eventSchemaVersion ?? this.eventSchemaVersion,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  LocalEvent copyWithCompanion(LocalEventsCompanion data) {
    return LocalEvent(
      localPosition: data.localPosition.present
          ? data.localPosition.value
          : this.localPosition,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      recordedAtUtcMicros: data.recordedAtUtcMicros.present
          ? data.recordedAtUtcMicros.value
          : this.recordedAtUtcMicros,
      businessDate: data.businessDate.present
          ? data.businessDate.value
          : this.businessDate,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      eventSchemaVersion: data.eventSchemaVersion.present
          ? data.eventSchemaVersion.value
          : this.eventSchemaVersion,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEvent(')
          ..write('localPosition: $localPosition, ')
          ..write('eventId: $eventId, ')
          ..write('recordedAtUtcMicros: $recordedAtUtcMicros, ')
          ..write('businessDate: $businessDate, ')
          ..write('entityKind: $entityKind, ')
          ..write('entityId: $entityId, ')
          ..write('eventType: $eventType, ')
          ..write('eventSchemaVersion: $eventSchemaVersion, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localPosition,
    eventId,
    recordedAtUtcMicros,
    businessDate,
    entityKind,
    entityId,
    eventType,
    eventSchemaVersion,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEvent &&
          other.localPosition == this.localPosition &&
          other.eventId == this.eventId &&
          other.recordedAtUtcMicros == this.recordedAtUtcMicros &&
          other.businessDate == this.businessDate &&
          other.entityKind == this.entityKind &&
          other.entityId == this.entityId &&
          other.eventType == this.eventType &&
          other.eventSchemaVersion == this.eventSchemaVersion &&
          other.payloadJson == this.payloadJson);
}

class LocalEventsCompanion extends UpdateCompanion<LocalEvent> {
  final Value<int> localPosition;
  final Value<String> eventId;
  final Value<int> recordedAtUtcMicros;
  final Value<String> businessDate;
  final Value<String> entityKind;
  final Value<String> entityId;
  final Value<String> eventType;
  final Value<int> eventSchemaVersion;
  final Value<String> payloadJson;
  const LocalEventsCompanion({
    this.localPosition = const Value.absent(),
    this.eventId = const Value.absent(),
    this.recordedAtUtcMicros = const Value.absent(),
    this.businessDate = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.eventSchemaVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
  });
  LocalEventsCompanion.insert({
    this.localPosition = const Value.absent(),
    required String eventId,
    required int recordedAtUtcMicros,
    required String businessDate,
    required String entityKind,
    required String entityId,
    required String eventType,
    required int eventSchemaVersion,
    required String payloadJson,
  }) : eventId = Value(eventId),
       recordedAtUtcMicros = Value(recordedAtUtcMicros),
       businessDate = Value(businessDate),
       entityKind = Value(entityKind),
       entityId = Value(entityId),
       eventType = Value(eventType),
       eventSchemaVersion = Value(eventSchemaVersion),
       payloadJson = Value(payloadJson);
  static Insertable<LocalEvent> custom({
    Expression<int>? localPosition,
    Expression<String>? eventId,
    Expression<int>? recordedAtUtcMicros,
    Expression<String>? businessDate,
    Expression<String>? entityKind,
    Expression<String>? entityId,
    Expression<String>? eventType,
    Expression<int>? eventSchemaVersion,
    Expression<String>? payloadJson,
  }) {
    return RawValuesInsertable({
      if (localPosition != null) 'local_position': localPosition,
      if (eventId != null) 'event_id': eventId,
      if (recordedAtUtcMicros != null)
        'recorded_at_utc_micros': recordedAtUtcMicros,
      if (businessDate != null) 'business_date': businessDate,
      if (entityKind != null) 'entity_kind': entityKind,
      if (entityId != null) 'entity_id': entityId,
      if (eventType != null) 'event_type': eventType,
      if (eventSchemaVersion != null)
        'event_schema_version': eventSchemaVersion,
      if (payloadJson != null) 'payload_json': payloadJson,
    });
  }

  LocalEventsCompanion copyWith({
    Value<int>? localPosition,
    Value<String>? eventId,
    Value<int>? recordedAtUtcMicros,
    Value<String>? businessDate,
    Value<String>? entityKind,
    Value<String>? entityId,
    Value<String>? eventType,
    Value<int>? eventSchemaVersion,
    Value<String>? payloadJson,
  }) {
    return LocalEventsCompanion(
      localPosition: localPosition ?? this.localPosition,
      eventId: eventId ?? this.eventId,
      recordedAtUtcMicros: recordedAtUtcMicros ?? this.recordedAtUtcMicros,
      businessDate: businessDate ?? this.businessDate,
      entityKind: entityKind ?? this.entityKind,
      entityId: entityId ?? this.entityId,
      eventType: eventType ?? this.eventType,
      eventSchemaVersion: eventSchemaVersion ?? this.eventSchemaVersion,
      payloadJson: payloadJson ?? this.payloadJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localPosition.present) {
      map['local_position'] = Variable<int>(localPosition.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (recordedAtUtcMicros.present) {
      map['recorded_at_utc_micros'] = Variable<int>(recordedAtUtcMicros.value);
    }
    if (businessDate.present) {
      map['business_date'] = Variable<String>(businessDate.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (eventSchemaVersion.present) {
      map['event_schema_version'] = Variable<int>(eventSchemaVersion.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEventsCompanion(')
          ..write('localPosition: $localPosition, ')
          ..write('eventId: $eventId, ')
          ..write('recordedAtUtcMicros: $recordedAtUtcMicros, ')
          ..write('businessDate: $businessDate, ')
          ..write('entityKind: $entityKind, ')
          ..write('entityId: $entityId, ')
          ..write('eventType: $eventType, ')
          ..write('eventSchemaVersion: $eventSchemaVersion, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$RebootDatabase extends GeneratedDatabase {
  _$RebootDatabase(QueryExecutor e) : super(e);
  $RebootDatabaseManager get managers => $RebootDatabaseManager(this);
  late final $LocalEventsTable localEvents = $LocalEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localEvents];
}

typedef $$LocalEventsTableCreateCompanionBuilder =
    LocalEventsCompanion Function({
      Value<int> localPosition,
      required String eventId,
      required int recordedAtUtcMicros,
      required String businessDate,
      required String entityKind,
      required String entityId,
      required String eventType,
      required int eventSchemaVersion,
      required String payloadJson,
    });
typedef $$LocalEventsTableUpdateCompanionBuilder =
    LocalEventsCompanion Function({
      Value<int> localPosition,
      Value<String> eventId,
      Value<int> recordedAtUtcMicros,
      Value<String> businessDate,
      Value<String> entityKind,
      Value<String> entityId,
      Value<String> eventType,
      Value<int> eventSchemaVersion,
      Value<String> payloadJson,
    });

class $$LocalEventsTableFilterComposer
    extends Composer<_$RebootDatabase, $LocalEventsTable> {
  $$LocalEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localPosition => $composableBuilder(
    column: $table.localPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAtUtcMicros => $composableBuilder(
    column: $table.recordedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessDate => $composableBuilder(
    column: $table.businessDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventSchemaVersion => $composableBuilder(
    column: $table.eventSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEventsTableOrderingComposer
    extends Composer<_$RebootDatabase, $LocalEventsTable> {
  $$LocalEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localPosition => $composableBuilder(
    column: $table.localPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAtUtcMicros => $composableBuilder(
    column: $table.recordedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessDate => $composableBuilder(
    column: $table.businessDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventSchemaVersion => $composableBuilder(
    column: $table.eventSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEventsTableAnnotationComposer
    extends Composer<_$RebootDatabase, $LocalEventsTable> {
  $$LocalEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localPosition => $composableBuilder(
    column: $table.localPosition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<int> get recordedAtUtcMicros => $composableBuilder(
    column: $table.recordedAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessDate => $composableBuilder(
    column: $table.businessDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get eventSchemaVersion => $composableBuilder(
    column: $table.eventSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$LocalEventsTableTableManager
    extends
        RootTableManager<
          _$RebootDatabase,
          $LocalEventsTable,
          LocalEvent,
          $$LocalEventsTableFilterComposer,
          $$LocalEventsTableOrderingComposer,
          $$LocalEventsTableAnnotationComposer,
          $$LocalEventsTableCreateCompanionBuilder,
          $$LocalEventsTableUpdateCompanionBuilder,
          (
            LocalEvent,
            BaseReferences<_$RebootDatabase, $LocalEventsTable, LocalEvent>,
          ),
          LocalEvent,
          PrefetchHooks Function()
        > {
  $$LocalEventsTableTableManager(_$RebootDatabase db, $LocalEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localPosition = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<int> recordedAtUtcMicros = const Value.absent(),
                Value<String> businessDate = const Value.absent(),
                Value<String> entityKind = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> eventSchemaVersion = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
              }) => LocalEventsCompanion(
                localPosition: localPosition,
                eventId: eventId,
                recordedAtUtcMicros: recordedAtUtcMicros,
                businessDate: businessDate,
                entityKind: entityKind,
                entityId: entityId,
                eventType: eventType,
                eventSchemaVersion: eventSchemaVersion,
                payloadJson: payloadJson,
              ),
          createCompanionCallback:
              ({
                Value<int> localPosition = const Value.absent(),
                required String eventId,
                required int recordedAtUtcMicros,
                required String businessDate,
                required String entityKind,
                required String entityId,
                required String eventType,
                required int eventSchemaVersion,
                required String payloadJson,
              }) => LocalEventsCompanion.insert(
                localPosition: localPosition,
                eventId: eventId,
                recordedAtUtcMicros: recordedAtUtcMicros,
                businessDate: businessDate,
                entityKind: entityKind,
                entityId: entityId,
                eventType: eventType,
                eventSchemaVersion: eventSchemaVersion,
                payloadJson: payloadJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$RebootDatabase,
      $LocalEventsTable,
      LocalEvent,
      $$LocalEventsTableFilterComposer,
      $$LocalEventsTableOrderingComposer,
      $$LocalEventsTableAnnotationComposer,
      $$LocalEventsTableCreateCompanionBuilder,
      $$LocalEventsTableUpdateCompanionBuilder,
      (
        LocalEvent,
        BaseReferences<_$RebootDatabase, $LocalEventsTable, LocalEvent>,
      ),
      LocalEvent,
      PrefetchHooks Function()
    >;

class $RebootDatabaseManager {
  final _$RebootDatabase _db;
  $RebootDatabaseManager(this._db);
  $$LocalEventsTableTableManager get localEvents =>
      $$LocalEventsTableTableManager(_db, _db.localEvents);
}
