import 'dart:io';
import 'dart:typed_data' as typed;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' as sqlite;

part 'database.g.dart';

/// Immutable rows in the one local append-only event journal.
class LocalEvents extends Table {
  @override
  String get tableName => 'local_events';

  /// Monotone position assigned by this local database only.
  IntColumn get localPosition =>
      integer().named('local_position').autoIncrement()();

  /// Globally stable event UUID.
  TextColumn get eventId => text().named('event_id').unique()();

  /// UTC microseconds since Unix epoch.
  IntColumn get recordedAtUtcMicros =>
      integer().named('recorded_at_utc_micros')();

  /// ISO local civil business date.
  TextColumn get businessDate => text().named('business_date')();

  /// Stable target entity family.
  TextColumn get entityKind => text().named('entity_kind')();

  /// Stable target entity UUID.
  TextColumn get entityId => text().named('entity_id')();

  /// Stable event payload type.
  TextColumn get eventType => text().named('event_type')();

  /// Positive payload schema version.
  IntColumn get eventSchemaVersion => integer()
      .named('event_schema_version')
      .check(const CustomExpression('event_schema_version > 0'))();

  /// Canonical JSON payload. The containing database page is encrypted.
  TextColumn get payloadJson => text().named('payload_json')();

  @override
  bool get isStrict => true;
}

/// Drift schema hosted inside one encrypted SQLite3MultipleCiphers file.
@DriftDatabase(tables: [LocalEvents])
final class RebootDatabase extends _$RebootDatabase {
  RebootDatabase._(super.executor);

  /// Opens an encrypted file using one background writer isolate.
  static Future<RebootDatabase> open({
    required String filePath,
    required EncryptedDatabaseKey key,
  }) async {
    if (!path.isAbsolute(filePath)) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'The encrypted database path must be absolute.',
      );
    }
    final file = File(filePath);
    await file.parent.create(recursive: true);

    final keyBytes = key.copyBytes();
    final keyHex = _hex(keyBytes);
    keyBytes.fillRange(0, keyBytes.length, 0);
    final executor = NativeDatabase.createInBackground(
      file,
      logStatements: false,
      readPool: 0,
      setup: (database) => _configureEncryptedConnection(database, keyHex),
    );
    final database = RebootDatabase._(executor);
    try {
      await database.customSelect('SELECT 1').getSingle();
      return database;
    } on Object catch (error) {
      await database.close();
      throw EncryptedStorageOpenException(_failureReason(error));
    }
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement('''
        CREATE TRIGGER local_events_reject_update
        BEFORE UPDATE ON local_events
        BEGIN
          SELECT RAISE(ABORT, 'local event journal is append-only');
        END
      ''');
      await customStatement('''
        CREATE TRIGGER local_events_reject_delete
        BEFORE DELETE ON local_events
        BEGIN
          SELECT RAISE(ABORT, 'local event journal is append-only');
        END
      ''');
    },
    onUpgrade: (migrator, from, to) async {
      throw StateError('No migration exists from schema $from to $to.');
    },
    beforeOpen: (details) async {
      final foreignKeys = await customSelect('PRAGMA foreign_keys').getSingle();
      if (foreignKeys.read<int>('foreign_keys') != 1) {
        throw StateError('SQLite foreign-key enforcement is unavailable.');
      }
    },
  );
}

/// Exact 256-bit key supplied by the application composition root.
final class EncryptedDatabaseKey {
  /// Copies and validates [bytes] without exposing a mutable reference.
  EncryptedDatabaseKey(typed.Uint8List bytes)
    : _bytes = typed.Uint8List.fromList(bytes) {
    if (bytes.length != 32) {
      throw ArgumentError.value(
        bytes.length,
        'bytes',
        'An encrypted REBOOT database key must contain exactly 32 bytes.',
      );
    }
  }

  final typed.Uint8List _bytes;
  bool _destroyed = false;

  typed.Uint8List copyBytes() {
    if (_destroyed) {
      throw StateError('The encrypted database key has been destroyed.');
    }
    return typed.Uint8List.fromList(_bytes);
  }

  /// Overwrites this wrapper's in-memory key material after database opening.
  void destroy() {
    if (_destroyed) {
      return;
    }
    _bytes.fillRange(0, _bytes.length, 0);
    _destroyed = true;
  }
}

/// Sanitized failure that never embeds a key, path, SQL statement, or amount.
final class EncryptedStorageOpenException implements Exception {
  /// Creates a fail-closed database-open error.
  const EncryptedStorageOpenException(this.reason);

  /// Sanitized setup stage that failed.
  final EncryptedStorageFailureReason reason;

  @override
  String toString() {
    return 'EncryptedStorageOpenException: ${reason.name}';
  }
}

/// Non-sensitive categories for encrypted storage setup failures.
enum EncryptedStorageFailureReason {
  /// SQLite3MultipleCiphers could not be proven at runtime.
  encryptionEngineUnavailable,

  /// The key did not open the file, or the encrypted file is corrupt.
  keyRejectedOrCorruptDatabase,

  /// Required durability or integrity settings could not be applied.
  requiredSettingsUnavailable,

  /// Drift could not validate or migrate the local schema.
  schemaUnavailable,
}

void _configureEncryptedConnection(sqlite.Database database, String keyHex) {
  // Standard SQLite silently ignores unknown pragmas. Reading the selected
  // cipher before touching the encrypted schema proves that
  // SQLite3MultipleCiphers is loaded, including when an existing file is later
  // presented with a wrong key.
  try {
    database.execute("PRAGMA cipher = 'chacha20'");
    final selectedCipher = database.select('PRAGMA cipher');
    if (selectedCipher.isEmpty ||
        selectedCipher.first.values.first.toString() != 'chacha20') {
      throw StateError('cipher mismatch');
    }
  } on Object {
    throw StateError(_engineFailureMarker);
  }
  database.execute("PRAGMA key = 'raw:$keyHex'");

  // PRAGMA key reports success before the key is used. This read is mandatory
  // to prove that an existing file was opened with the correct key.
  try {
    database.select('SELECT count(*) AS object_count FROM sqlite_master');
  } on Object {
    throw StateError(_keyFailureMarker);
  }

  try {
    database
      ..execute('PRAGMA hmac_check = 1')
      ..execute('PRAGMA foreign_keys = ON')
      ..execute('PRAGMA journal_mode = WAL')
      ..execute('PRAGMA synchronous = FULL')
      ..execute('PRAGMA temp_store = MEMORY')
      ..execute('PRAGMA busy_timeout = 5000');

    _requirePragma(database, 'foreign_keys', 1);
    _requirePragma(database, 'synchronous', 2);
    _requirePragma(database, 'temp_store', 2);
    _requirePragma(database, 'hmac_check', 1);
    final journalMode = database.select('PRAGMA journal_mode');
    if (journalMode.isEmpty ||
        journalMode.first.values.first.toString().toLowerCase() != 'wal') {
      throw StateError('journal mode mismatch');
    }
  } on Object {
    throw StateError(_settingsFailureMarker);
  }
}

void _requirePragma(sqlite.Database database, String name, int expected) {
  final rows = database.select('PRAGMA $name');
  if (rows.isEmpty || rows.first.values.first.toString() != '$expected') {
    throw StateError('Required SQLite setting is unavailable.');
  }
}

String _hex(typed.Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

const String _engineFailureMarker = 'reboot_storage_engine_unavailable';
const String _keyFailureMarker = 'reboot_storage_key_rejected';
const String _settingsFailureMarker = 'reboot_storage_settings_unavailable';

EncryptedStorageFailureReason _failureReason(Object error) {
  final message = error.toString();
  if (message.contains(_engineFailureMarker)) {
    return EncryptedStorageFailureReason.encryptionEngineUnavailable;
  }
  if (message.contains(_keyFailureMarker)) {
    return EncryptedStorageFailureReason.keyRejectedOrCorruptDatabase;
  }
  if (message.contains(_settingsFailureMarker)) {
    return EncryptedStorageFailureReason.requiredSettingsUnavailable;
  }
  return EncryptedStorageFailureReason.schemaUnavailable;
}
