import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'encrypted_event_envelope.dart';
import 'encrypted_projection_snapshot.dart';

/// Browser-only proof that clear event payloads never enter IndexedDB.
///
/// This class is deliberately not wired to the production application port.
final class BrowserEncryptedJournalPrototype {
  BrowserEncryptedJournalPrototype._({
    required this._database,
    required this._dataKey,
    required this.databaseName,
  });

  static const int schemaVersion = 2;
  static const int _legacySchemaVersion = 1;
  static const String _keyStore = 'keys';
  static const String _metadataStore = 'metadata';
  static const String _entryStore = 'entries';
  static const String _eventIdStore = 'event_ids';
  static const String _snapshotStore = 'projection_snapshots';
  static const String _initializedKey = 'initialized';
  static const String _lastPositionKey = 'last_position';
  static const String _latestSnapshotKey = 'latest';
  static const String _markerPrefix = 'reboot.web.prototype.marker.';
  static final BigInt _maximumPosition = BigInt.parse('9223372036854775807');

  final web.IDBDatabase _database;
  final web.CryptoKey _dataKey;
  final String databaseName;
  Future<void> _appendTail = Future<void>.value();
  bool _closed = false;

  bool get keyIsNonExtractable => !_dataKey.extractable;

  /// Proves that the browser refuses raw export of the persisted key.
  Future<bool> keyExportIsRejectedForTesting() async {
    _ensureOpen();
    try {
      await web.window.crypto.subtle.exportKey('raw', _dataKey).toDart;
      return false;
    } on Object {
      return true;
    }
  }

  static Future<BrowserEncryptedJournalPrototype> open({
    required String databaseName,
  }) async {
    if (databaseName.isEmpty || databaseName.length > 100) {
      throw ArgumentError.value(databaseName, 'databaseName');
    }
    final opened = await _openDatabase(databaseName);
    try {
      final markerExists = _readMarker(databaseName);
      final initialized = await _readValue(
        opened.database,
        _metadataStore,
        _initializedKey,
      );
      final storedKey = await _readValue(
        opened.database,
        _keyStore,
        WebEncryptedEventEnvelope.keyId,
      );

      if (initialized == null && storedKey == null) {
        if (!opened.created || markerExists) {
          throw const WebJournalKeyUnavailableException();
        }
        final key = await _generateDataKey();
        await _initialize(opened.database, key);
        _writeMarker(databaseName);
        return BrowserEncryptedJournalPrototype._(
          database: opened.database,
          dataKey: key,
          databaseName: databaseName,
        );
      }

      if (initialized?.dartify() != '1' || storedKey == null) {
        throw const WebJournalKeyUnavailableException();
      }
      final web.CryptoKey key;
      try {
        key = storedKey as web.CryptoKey;
        if (!_isExpectedDataKey(key)) {
          throw const WebJournalKeyUnavailableException();
        }
      } on WebJournalKeyUnavailableException {
        rethrow;
      } on Object {
        throw const WebJournalKeyUnavailableException();
      }
      if (!markerExists) _writeMarker(databaseName);
      return BrowserEncryptedJournalPrototype._(
        database: opened.database,
        dataKey: key,
        databaseName: databaseName,
      );
    } on Object {
      opened.database.close();
      rethrow;
    }
  }

  /// Creates a valid version-one database so browser tests can prove that the
  /// version-two snapshot migration preserves the encrypted journal and key.
  static Future<void> createLegacyVersionOneForTesting({
    required String databaseName,
    required WebPrototypePlainEvent event,
  }) async {
    final opened = await _openDatabase(
      databaseName,
      version: _legacySchemaVersion,
    );
    if (!opened.created) {
      opened.database.close();
      throw StateError('The legacy test database already exists.');
    }
    try {
      final key = await _generateDataKey();
      await _initialize(opened.database, key);
      _writeMarker(databaseName);
      final journal = BrowserEncryptedJournalPrototype._(
        database: opened.database,
        dataKey: key,
        databaseName: databaseName,
      );
      try {
        await journal.append(event);
      } finally {
        journal.close();
      }
    } on Object {
      opened.database.close();
      rethrow;
    }
  }

  /// Appends an immutable encrypted event and returns its exact local position.
  Future<BigInt> append(WebPrototypePlainEvent event) {
    _ensureOpen();
    final completer = Completer<BigInt>();
    _appendTail = _appendTail.then((_) async {
      try {
        completer.complete(await _appendSerialized(event));
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<BigInt> _appendSerialized(WebPrototypePlainEvent event) async {
    for (var attempt = 0; attempt < 8; attempt += 1) {
      final existing = await _readByEventId(event.eventId);
      if (existing != null) {
        final decrypted = await _decrypt(existing);
        if (decrypted == event) return existing.position;
        throw const WebJournalEventConflictException();
      }

      final observedLast = await _readLastPosition();
      if (observedLast >= _maximumPosition) {
        throw const WebJournalStorageException();
      }
      final nextPosition = observedLast + BigInt.one;
      final envelope = await _encrypt(nextPosition, event);
      final result = await _tryCommit(
        observedLast: observedLast,
        envelope: envelope,
      );
      if (result == _CommitResult.committed) return nextPosition;
    }
    throw const WebJournalStorageException();
  }

  /// Reads, authenticates and decrypts every event in monotone position order.
  Future<List<WebPrototypePlainEvent>> readAll() async {
    _ensureOpen();
    final snapshot = await _readIntegritySnapshot(_database);
    final values = snapshot.entries;
    if (BigInt.from(values.length) != snapshot.lastPosition ||
        snapshot.eventIds.length != values.length) {
      throw const WebJournalIntegrityException();
    }

    final result = <WebPrototypePlainEvent>[];
    var expected = BigInt.one;
    for (final value in values) {
      try {
        final envelope = WebEncryptedEventEnvelope.fromPersistedMap(
          _dartMap(value),
        );
        if (envelope.position != expected) {
          throw const WebJournalIntegrityException();
        }
        if (snapshot.eventIds[envelope.eventId] != envelope.positionKey) {
          throw const WebJournalIntegrityException();
        }
        result.add(await _decrypt(envelope));
        expected += BigInt.one;
      } on WebJournalIntegrityException {
        rethrow;
      } on Object {
        throw const WebJournalIntegrityException();
      }
    }
    return List<WebPrototypePlainEvent>.unmodifiable(result);
  }

  /// Reads only the authenticated journal suffix strictly after [position].
  ///
  /// This is the fast-start companion to a validated projection snapshot. It
  /// still checks contiguous positions and every suffix UUID index entry.
  Future<List<WebPrototypePlainEvent>> readAfter(BigInt position) async {
    _ensureOpen();
    if (position < BigInt.zero || position > _maximumPosition) {
      throw ArgumentError.value(position, 'position', 'Outside signed int64.');
    }
    final suffix = await _readEntriesAfter(_database, position);
    if (position > suffix.lastPosition) {
      throw ArgumentError.value(
        position,
        'position',
        'Beyond the current journal tail.',
      );
    }
    final envelopes = <WebEncryptedEventEnvelope>[];
    var expected = position + BigInt.one;
    for (final value in suffix.entries) {
      try {
        final envelope = WebEncryptedEventEnvelope.fromPersistedMap(
          _dartMap(value),
        );
        if (envelope.position != expected) {
          throw const WebJournalIntegrityException();
        }
        envelopes.add(envelope);
        expected += BigInt.one;
      } on WebJournalIntegrityException {
        rethrow;
      } on Object {
        throw const WebJournalIntegrityException();
      }
    }
    if (expected - BigInt.one != suffix.lastPosition) {
      throw const WebJournalIntegrityException();
    }

    final indexedPositions = await _readIndexedPositions(
      _database,
      envelopes.map((envelope) => envelope.eventId).toList(growable: false),
    );
    final result = <WebPrototypePlainEvent>[];
    for (var index = 0; index < envelopes.length; index += 1) {
      final envelope = envelopes[index];
      if (indexedPositions[index] != envelope.positionKey) {
        throw const WebJournalIntegrityException();
      }
      result.add(await _decrypt(envelope));
    }
    return List<WebPrototypePlainEvent>.unmodifiable(result);
  }

  /// Replaces the derived projection cache at the exact current journal tail.
  ///
  /// The snapshot is mutable and disposable; journal entries remain the only
  /// source of truth and are never changed by this operation.
  Future<void> writeProjectionSnapshot(
    WebPrototypeProjectionSnapshot snapshot,
  ) async {
    _ensureOpen();
    final lastPosition = await _readLastPosition();
    if (snapshot.journalPosition != lastPosition) {
      throw const WebJournalSnapshotPositionException();
    }
    final eventEnvelope = await _readEnvelopeAt(snapshot.journalPosition);
    final anchor = await _journalAnchor(eventEnvelope);
    final encrypted = await _encryptProjectionSnapshot(snapshot, anchor);
    await _putValue(
      _database,
      _snapshotStore,
      _latestSnapshotKey,
      encrypted.toPersistedMap().jsify(),
    );
  }

  /// Returns the latest valid derived projection cache, or null when absent or
  /// disposable corruption is detected.
  Future<WebPrototypeProjectionSnapshot?> readProjectionSnapshot() async {
    _ensureOpen();
    final raw = await _readValue(_database, _snapshotStore, _latestSnapshotKey);
    if (raw == null) return null;

    final WebEncryptedProjectionSnapshotEnvelope encrypted;
    try {
      encrypted = WebEncryptedProjectionSnapshotEnvelope.fromPersistedMap(
        _dartMap(raw),
      );
    } on Object {
      return _discardProjectionSnapshot();
    }

    final lastPosition = await _readLastPosition();
    if (encrypted.journalPosition > lastPosition) {
      return _discardProjectionSnapshot();
    }

    final eventEnvelope = await _readEnvelopeAt(encrypted.journalPosition);
    final expectedAnchor = await _journalAnchor(eventEnvelope);
    if (encrypted.journalAnchorBase64Url != expectedAnchor) {
      return _discardProjectionSnapshot();
    }

    try {
      return await _decryptProjectionSnapshot(encrypted);
    } on WebJournalIntegrityException {
      return _discardProjectionSnapshot();
    }
  }

  /// Returns opaque persisted records for confidentiality assertions only.
  Future<List<Map<String, Object?>>> inspectEncryptedRecordsForTesting() async {
    _ensureOpen();
    final values = await _readAllValues(_database, _entryStore);
    return List<Map<String, Object?>>.unmodifiable(values.map(_dartMap));
  }

  Future<Map<String, Object?>?> inspectEncryptedSnapshotForTesting() async {
    _ensureOpen();
    final raw = await _readValue(_database, _snapshotStore, _latestSnapshotKey);
    return raw == null ? null : _dartMap(raw);
  }

  /// Corrupts one ciphertext so browser integration tests can prove fail-closed.
  Future<void> corruptCiphertextForTesting(BigInt position) async {
    _ensureOpen();
    final key = _positionKey(position);
    final raw = await _readValue(_database, _entryStore, key);
    if (raw == null) throw StateError('Missing prototype entry.');
    final map = _dartMap(raw);
    final ciphertext = map['ciphertext']! as String;
    map['ciphertext'] =
        '${ciphertext.startsWith('A') ? 'B' : 'A'}'
        '${ciphertext.substring(1)}';
    await _putValue(_database, _entryStore, key, map.jsify());
  }

  /// Alters authenticated clear routing metadata without touching ciphertext.
  Future<void> corruptEventIdForTesting(
    BigInt position,
    String replacementEventId,
  ) async {
    _ensureOpen();
    final key = _positionKey(position);
    final raw = await _readValue(_database, _entryStore, key);
    if (raw == null) throw StateError('Missing prototype entry.');
    final map = _dartMap(raw)..['eventId'] = replacementEventId;
    await _putValue(_database, _entryStore, key, map.jsify());
  }

  /// Deletes the non-extractable key to prove that reopening never regenerates.
  Future<void> deleteKeyForTesting() async {
    _ensureOpen();
    await _deleteValue(_database, _keyStore, WebEncryptedEventEnvelope.keyId);
  }

  /// Corrupts the metadata tail so tests can prove whole-journal validation.
  Future<void> corruptLastPositionForTesting(String replacement) async {
    _ensureOpen();
    await _putValue(
      _database,
      _metadataStore,
      _lastPositionKey,
      replacement.toJS,
    );
  }

  /// Removes one UUID index entry while retaining its encrypted envelope.
  Future<void> deleteEventIdIndexForTesting(String eventId) async {
    _ensureOpen();
    await _deleteValue(_database, _eventIdStore, eventId);
  }

  Future<void> corruptSnapshotCiphertextForTesting() async {
    _ensureOpen();
    final raw = await _readValue(_database, _snapshotStore, _latestSnapshotKey);
    if (raw == null) throw StateError('Missing projection snapshot.');
    final map = _dartMap(raw);
    final ciphertext = map['ciphertext']! as String;
    map['ciphertext'] =
        '${ciphertext.startsWith('A') ? 'B' : 'A'}${ciphertext.substring(1)}';
    await _putValue(_database, _snapshotStore, _latestSnapshotKey, map.jsify());
  }

  /// Forces one request in a read/write transaction to fail so tests can
  /// prove that sibling writes are rolled back atomically.
  Future<void> forceTransactionFailureForTesting() async {
    _ensureOpen();
    final transaction = _database.transaction(
      <JSString>[_entryStore.toJS, _metadataStore.toJS].toJS,
      'readwrite',
    );
    final completed = _transactionCompleted(transaction);
    try {
      await Future.wait(<Future<JSAny?>>[
        _requestResult(
          transaction
              .objectStore(_entryStore)
              .add(<String, Object?>{}.jsify(), _positionKey(BigInt.one).toJS),
        ),
        _requestResult(
          transaction
              .objectStore(_metadataStore)
              .put('999'.toJS, _lastPositionKey.toJS),
        ),
      ]);
      await completed;
      throw StateError('The forced IndexedDB failure unexpectedly committed.');
    } on StateError {
      rethrow;
    } on Object {
      await _ignoreAbort(completed);
      throw const WebJournalStorageException();
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _database.close();
  }

  /// Deletes only IndexedDB while retaining the independent loss marker.
  static Future<void> deleteDatabaseForTesting(String databaseName) async {
    final request = web.window.indexedDB.deleteDatabase(databaseName);
    await _requestResult(request);
  }

  /// Removes the non-sensitive marker after a test has deleted its database.
  static void removeMarkerForTesting(String databaseName) {
    web.window.localStorage.removeItem('$_markerPrefix$databaseName');
  }

  Future<_CommitResult> _tryCommit({
    required BigInt observedLast,
    required WebEncryptedEventEnvelope envelope,
  }) async {
    final transaction = _database.transaction(
      <JSString>[
        _metadataStore.toJS,
        _entryStore.toJS,
        _eventIdStore.toJS,
      ].toJS,
      'readwrite',
    );
    final completed = _transactionCompleted(transaction);
    try {
      final eventIds = transaction.objectStore(_eventIdStore);
      final existing = await _requestResult(
        eventIds.get(envelope.eventId.toJS),
      );
      if (existing != null) {
        transaction.abort();
        await _ignoreAbort(completed);
        return _CommitResult.retry;
      }

      final metadata = transaction.objectStore(_metadataStore);
      final currentRaw = await _requestResult(
        metadata.get(_lastPositionKey.toJS),
      );
      final current = _parsePosition(currentRaw, allowZero: true);
      if (current != observedLast) {
        transaction.abort();
        await _ignoreAbort(completed);
        return _CommitResult.retry;
      }

      final entries = transaction.objectStore(_entryStore);
      await Future.wait(<Future<JSAny?>>[
        _requestResult(
          entries.add(
            envelope.toPersistedMap().jsify(),
            envelope.positionKey.toJS,
          ),
        ),
        _requestResult(
          eventIds.add(envelope.positionKey.toJS, envelope.eventId.toJS),
        ),
        _requestResult(
          metadata.put(
            envelope.position.toString().toJS,
            _lastPositionKey.toJS,
          ),
        ),
      ]);
      await completed;
      return _CommitResult.committed;
    } on WebJournalStorageException {
      await _ignoreAbort(completed);
      rethrow;
    } on Object {
      await _ignoreAbort(completed);
      throw const WebJournalStorageException();
    }
  }

  Future<WebEncryptedEventEnvelope?> _readByEventId(String eventId) async {
    final positionRaw = await _readValue(_database, _eventIdStore, eventId);
    if (positionRaw == null) return null;
    final positionKey = positionRaw.dartify();
    if (positionKey is! String) {
      throw const WebJournalIntegrityException();
    }
    final envelopeRaw = await _readValue(_database, _entryStore, positionKey);
    if (envelopeRaw == null) throw const WebJournalIntegrityException();
    try {
      return WebEncryptedEventEnvelope.fromPersistedMap(_dartMap(envelopeRaw));
    } on Object {
      throw const WebJournalIntegrityException();
    }
  }

  Future<BigInt> _readLastPosition() async {
    final raw = await _readValue(_database, _metadataStore, _lastPositionKey);
    return _parsePosition(raw, allowZero: true);
  }

  Future<WebEncryptedEventEnvelope> _readEnvelopeAt(BigInt position) async {
    final raw = await _readValue(
      _database,
      _entryStore,
      _positionKey(position),
    );
    if (raw == null) throw const WebJournalIntegrityException();
    try {
      final envelope = WebEncryptedEventEnvelope.fromPersistedMap(
        _dartMap(raw),
      );
      if (envelope.position != position) {
        throw const WebJournalIntegrityException();
      }
      return envelope;
    } on WebJournalIntegrityException {
      rethrow;
    } on Object {
      throw const WebJournalIntegrityException();
    }
  }

  Future<WebEncryptedEventEnvelope> _encrypt(
    BigInt position,
    WebPrototypePlainEvent event,
  ) async {
    final nonce = Uint8List(WebEncryptedEventEnvelope.nonceLengthBytes);
    web.window.crypto.getRandomValues(nonce.toJS);
    final provisional = WebEncryptedEventEnvelope(
      position: position,
      eventId: event.eventId,
      nonceBase64Url: encodeBase64UrlCanonical(nonce),
      ciphertextBase64Url: encodeBase64UrlCanonical(
        List<int>.filled(
          WebEncryptedEventEnvelope.authenticationTagLengthBytes,
          0,
        ),
      ),
    );
    try {
      final encrypted = await web.window.crypto.subtle
          .encrypt(
            <String, Object?>{
              'name': 'AES-GCM',
              'iv': nonce,
              'additionalData': Uint8List.fromList(
                provisional.authenticatedData(),
              ),
              'tagLength': 128,
            }.jsify()!,
            _dataKey,
            Uint8List.fromList(event.encode()).toJS,
          )
          .toDart;
      final ciphertext = _arrayBufferBytes(encrypted);
      return WebEncryptedEventEnvelope(
        position: position,
        eventId: event.eventId,
        nonceBase64Url: provisional.nonceBase64Url,
        ciphertextBase64Url: encodeBase64UrlCanonical(ciphertext),
      );
    } on Object {
      throw const WebJournalStorageException();
    }
  }

  Future<WebPrototypePlainEvent> _decrypt(
    WebEncryptedEventEnvelope envelope,
  ) async {
    try {
      final nonce = Uint8List.fromList(
        decodeBase64UrlCanonical(envelope.nonceBase64Url, 'nonce'),
      );
      final ciphertext = Uint8List.fromList(
        decodeBase64UrlCanonical(envelope.ciphertextBase64Url, 'ciphertext'),
      );
      final decrypted = await web.window.crypto.subtle
          .decrypt(
            <String, Object?>{
              'name': 'AES-GCM',
              'iv': nonce,
              'additionalData': Uint8List.fromList(
                envelope.authenticatedData(),
              ),
              'tagLength': 128,
            }.jsify()!,
            _dataKey,
            ciphertext.toJS,
          )
          .toDart;
      return WebPrototypePlainEvent.decode(
        eventId: envelope.eventId,
        bytes: _arrayBufferBytes(decrypted),
      );
    } on Object {
      throw const WebJournalIntegrityException();
    }
  }

  Future<String> _journalAnchor(WebEncryptedEventEnvelope envelope) async {
    try {
      final canonicalEnvelope = utf8.encode(
        jsonEncode(envelope.toPersistedMap()),
      );
      final digest = await web.window.crypto.subtle
          .digest('SHA-256'.toJS, Uint8List.fromList(canonicalEnvelope).toJS)
          .toDart;
      return encodeBase64UrlCanonical(_arrayBufferBytes(digest));
    } on Object {
      throw const WebJournalStorageException();
    }
  }

  Future<WebEncryptedProjectionSnapshotEnvelope> _encryptProjectionSnapshot(
    WebPrototypeProjectionSnapshot snapshot,
    String journalAnchor,
  ) async {
    final nonce = Uint8List(
      WebEncryptedProjectionSnapshotEnvelope.nonceLengthBytes,
    );
    web.window.crypto.getRandomValues(nonce.toJS);
    final provisional = WebEncryptedProjectionSnapshotEnvelope(
      journalPosition: snapshot.journalPosition,
      journalAnchorBase64Url: journalAnchor,
      nonceBase64Url: encodeBase64UrlCanonical(nonce),
      ciphertextBase64Url: encodeBase64UrlCanonical(
        List<int>.filled(
          WebEncryptedProjectionSnapshotEnvelope.authenticationTagLengthBytes,
          0,
        ),
      ),
    );
    try {
      final encrypted = await web.window.crypto.subtle
          .encrypt(
            <String, Object?>{
              'name': 'AES-GCM',
              'iv': nonce,
              'additionalData': Uint8List.fromList(
                provisional.authenticatedData(),
              ),
              'tagLength': 128,
            }.jsify()!,
            _dataKey,
            Uint8List.fromList(snapshot.encode()).toJS,
          )
          .toDart;
      return WebEncryptedProjectionSnapshotEnvelope(
        journalPosition: snapshot.journalPosition,
        journalAnchorBase64Url: journalAnchor,
        nonceBase64Url: provisional.nonceBase64Url,
        ciphertextBase64Url: encodeBase64UrlCanonical(
          _arrayBufferBytes(encrypted),
        ),
      );
    } on Object {
      throw const WebJournalStorageException();
    }
  }

  Future<WebPrototypeProjectionSnapshot> _decryptProjectionSnapshot(
    WebEncryptedProjectionSnapshotEnvelope envelope,
  ) async {
    try {
      final decrypted = await web.window.crypto.subtle
          .decrypt(
            <String, Object?>{
              'name': 'AES-GCM',
              'iv': Uint8List.fromList(
                decodeBase64UrlCanonical(envelope.nonceBase64Url, 'nonce'),
              ),
              'additionalData': Uint8List.fromList(
                envelope.authenticatedData(),
              ),
              'tagLength': 128,
            }.jsify()!,
            _dataKey,
            Uint8List.fromList(
              decodeBase64UrlCanonical(
                envelope.ciphertextBase64Url,
                'ciphertext',
              ),
            ).toJS,
          )
          .toDart;
      return WebPrototypeProjectionSnapshot.decode(
        journalPosition: envelope.journalPosition,
        bytes: _arrayBufferBytes(decrypted),
      );
    } on Object {
      throw const WebJournalIntegrityException();
    }
  }

  Future<WebPrototypeProjectionSnapshot?> _discardProjectionSnapshot() async {
    await _deleteValue(_database, _snapshotStore, _latestSnapshotKey);
    return null;
  }

  void _ensureOpen() {
    if (_closed) throw StateError('The prototype journal is closed.');
  }
}

enum _CommitResult { committed, retry }

({web.IDBDatabase database, bool created}) _openedResult(
  web.IDBOpenDBRequest request,
  bool created,
) => (database: request.result as web.IDBDatabase, created: created);

Future<({web.IDBDatabase database, bool created})> _openDatabase(
  String name, {
  int version = BrowserEncryptedJournalPrototype.schemaVersion,
}) {
  final completer = Completer<({web.IDBDatabase database, bool created})>();
  final request = web.window.indexedDB.open(name, version);
  var created = false;
  request.onupgradeneeded = ((web.Event event) {
    final versionChange = event as web.IDBVersionChangeEvent;
    created = versionChange.oldVersion == 0;
    final database = request.result as web.IDBDatabase;
    if (versionChange.oldVersion < 1) {
      database.createObjectStore(BrowserEncryptedJournalPrototype._keyStore);
      database.createObjectStore(
        BrowserEncryptedJournalPrototype._metadataStore,
      );
      database.createObjectStore(BrowserEncryptedJournalPrototype._entryStore);
      database.createObjectStore(
        BrowserEncryptedJournalPrototype._eventIdStore,
      );
    }
    if (versionChange.oldVersion < 2 && version >= 2) {
      database.createObjectStore(
        BrowserEncryptedJournalPrototype._snapshotStore,
      );
    }
  }).toJS;
  request.onsuccess = ((web.Event _) {
    if (!completer.isCompleted) {
      final result = _openedResult(request, created);
      result.database.onversionchange = ((web.Event _) {
        result.database.close();
      }).toJS;
      completer.complete(result);
    }
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(const WebJournalStorageException());
    }
  }).toJS;
  request.onblocked = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(const WebJournalStorageException());
    }
  }).toJS;
  return completer.future;
}

Future<web.CryptoKey> _generateDataKey() async {
  try {
    final generated = await web.window.crypto.subtle
        .generateKey(
          <String, Object?>{'name': 'AES-GCM', 'length': 256}.jsify()!,
          false,
          <JSString>['encrypt'.toJS, 'decrypt'.toJS].toJS,
        )
        .toDart;
    final key = generated as web.CryptoKey;
    if (!_isExpectedDataKey(key)) {
      throw const WebJournalStorageException();
    }
    return key;
  } on WebJournalStorageException {
    rethrow;
  } on Object {
    throw const WebJournalStorageException();
  }
}

bool _isExpectedDataKey(web.CryptoKey key) {
  if (key.extractable || key.type != 'secret') return false;
  final algorithm = key.algorithm.dartify();
  if (algorithm is! Map<Object?, Object?> ||
      algorithm['name'] != 'AES-GCM' ||
      algorithm['length'] != 256) {
    return false;
  }
  final usages = key.usages.dartify();
  if (usages is! List<Object?>) return false;
  return usages.length == 2 &&
      usages.toSet().containsAll(const <String>{'encrypt', 'decrypt'});
}

Future<void> _initialize(web.IDBDatabase database, web.CryptoKey key) async {
  final transaction = database.transaction(
    <JSString>[
      BrowserEncryptedJournalPrototype._keyStore.toJS,
      BrowserEncryptedJournalPrototype._metadataStore.toJS,
    ].toJS,
    'readwrite',
  );
  final completed = _transactionCompleted(transaction);
  try {
    await Future.wait(<Future<JSAny?>>[
      _requestResult(
        transaction
            .objectStore(BrowserEncryptedJournalPrototype._keyStore)
            .add(key, WebEncryptedEventEnvelope.keyId.toJS),
      ),
      _requestResult(
        transaction
            .objectStore(BrowserEncryptedJournalPrototype._metadataStore)
            .add(
              '1'.toJS,
              BrowserEncryptedJournalPrototype._initializedKey.toJS,
            ),
      ),
      _requestResult(
        transaction
            .objectStore(BrowserEncryptedJournalPrototype._metadataStore)
            .add(
              '0'.toJS,
              BrowserEncryptedJournalPrototype._lastPositionKey.toJS,
            ),
      ),
    ]);
    await completed;
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

Future<JSAny?> _readValue(
  web.IDBDatabase database,
  String storeName,
  String key,
) async {
  final transaction = database.transaction(storeName.toJS, 'readonly');
  final completed = _transactionCompleted(transaction);
  try {
    final result = await _requestResult(
      transaction.objectStore(storeName).get(key.toJS),
    );
    await completed;
    return result;
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

Future<List<JSAny?>> _readAllValues(
  web.IDBDatabase database,
  String storeName,
) async {
  final transaction = database.transaction(storeName.toJS, 'readonly');
  final completed = _transactionCompleted(transaction);
  try {
    final result = await _requestResult(
      transaction.objectStore(storeName).getAll(),
    );
    await completed;
    final array = result as JSArray<JSAny?>;
    return array.toDart;
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

Future<
  ({List<JSAny?> entries, Map<String, String> eventIds, BigInt lastPosition})
>
_readIntegritySnapshot(web.IDBDatabase database) async {
  final transaction = database.transaction(
    <JSString>[
      BrowserEncryptedJournalPrototype._metadataStore.toJS,
      BrowserEncryptedJournalPrototype._entryStore.toJS,
      BrowserEncryptedJournalPrototype._eventIdStore.toJS,
    ].toJS,
    'readonly',
  );
  final completed = _transactionCompleted(transaction);
  try {
    final metadata = transaction.objectStore(
      BrowserEncryptedJournalPrototype._metadataStore,
    );
    final entries = transaction.objectStore(
      BrowserEncryptedJournalPrototype._entryStore,
    );
    final eventIds = transaction.objectStore(
      BrowserEncryptedJournalPrototype._eventIdStore,
    );
    final results = await Future.wait(<Future<JSAny?>>[
      _requestResult(
        metadata.get(BrowserEncryptedJournalPrototype._lastPositionKey.toJS),
      ),
      _requestResult(entries.getAll()),
      _requestResult(eventIds.getAllKeys()),
      _requestResult(eventIds.getAll()),
    ]);
    await completed;

    final eventIdKeys = _jsArrayValues(results[2]);
    final eventIdPositions = _jsArrayValues(results[3]);
    if (eventIdKeys.length != eventIdPositions.length) {
      throw const WebJournalIntegrityException();
    }
    final eventIdIndex = <String, String>{};
    for (var index = 0; index < eventIdKeys.length; index += 1) {
      final eventId = eventIdKeys[index]?.dartify();
      final position = eventIdPositions[index]?.dartify();
      if (eventId is! String || position is! String) {
        throw const WebJournalIntegrityException();
      }
      if (eventIdIndex.putIfAbsent(eventId, () => position) != position) {
        throw const WebJournalIntegrityException();
      }
    }
    return (
      entries: _jsArrayValues(results[1]),
      eventIds: Map<String, String>.unmodifiable(eventIdIndex),
      lastPosition: _parsePosition(results[0], allowZero: true),
    );
  } on WebJournalIntegrityException {
    await _ignoreAbort(completed);
    rethrow;
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

Future<({List<JSAny?> entries, BigInt lastPosition})> _readEntriesAfter(
  web.IDBDatabase database,
  BigInt position,
) async {
  final transaction = database.transaction(
    <JSString>[
      BrowserEncryptedJournalPrototype._metadataStore.toJS,
      BrowserEncryptedJournalPrototype._entryStore.toJS,
    ].toJS,
    'readonly',
  );
  final completed = _transactionCompleted(transaction);
  try {
    final metadataRequest = transaction
        .objectStore(BrowserEncryptedJournalPrototype._metadataStore)
        .get(BrowserEncryptedJournalPrototype._lastPositionKey.toJS);
    final entries = transaction.objectStore(
      BrowserEncryptedJournalPrototype._entryStore,
    );
    final web.IDBRequest entriesRequest;
    if (position == BigInt.zero) {
      entriesRequest = entries.getAll();
    } else {
      entriesRequest = entries.getAll(
        web.IDBKeyRange.lowerBound(_positionKey(position).toJS, true),
      );
    }
    final results = await Future.wait(<Future<JSAny?>>[
      _requestResult(metadataRequest),
      _requestResult(entriesRequest),
    ]);
    await completed;
    return (
      entries: _jsArrayValues(results[1]),
      lastPosition: _parsePosition(results[0], allowZero: true),
    );
  } on WebJournalIntegrityException {
    await _ignoreAbort(completed);
    rethrow;
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

Future<List<String?>> _readIndexedPositions(
  web.IDBDatabase database,
  List<String> eventIds,
) async {
  if (eventIds.isEmpty) return const <String?>[];
  final transaction = database.transaction(
    BrowserEncryptedJournalPrototype._eventIdStore.toJS,
    'readonly',
  );
  final completed = _transactionCompleted(transaction);
  try {
    final store = transaction.objectStore(
      BrowserEncryptedJournalPrototype._eventIdStore,
    );
    final requests = eventIds
        .map((eventId) => _requestResult(store.get(eventId.toJS)))
        .toList(growable: false);
    final values = await Future.wait(requests);
    await completed;
    return values
        .map((value) => value?.dartify())
        .map((value) => value is String ? value : null)
        .toList(growable: false);
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

List<JSAny?> _jsArrayValues(JSAny? value) {
  try {
    return (value as JSArray<JSAny?>).toDart;
  } on Object {
    throw const WebJournalIntegrityException();
  }
}

Future<void> _putValue(
  web.IDBDatabase database,
  String storeName,
  String key,
  JSAny? value,
) async {
  final transaction = database.transaction(storeName.toJS, 'readwrite');
  final completed = _transactionCompleted(transaction);
  try {
    await _requestResult(
      transaction.objectStore(storeName).put(value, key.toJS),
    );
    await completed;
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

Future<void> _deleteValue(
  web.IDBDatabase database,
  String storeName,
  String key,
) async {
  final transaction = database.transaction(storeName.toJS, 'readwrite');
  final completed = _transactionCompleted(transaction);
  try {
    await _requestResult(transaction.objectStore(storeName).delete(key.toJS));
    await completed;
  } on Object {
    await _ignoreAbort(completed);
    throw const WebJournalStorageException();
  }
}

Future<JSAny?> _requestResult(web.IDBRequest request) {
  final completer = Completer<JSAny?>.sync();
  request.onsuccess = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(request.result);
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(const WebJournalStorageException());
    }
  }).toJS;
  return completer.future;
}

Future<void> _transactionCompleted(web.IDBTransaction transaction) {
  final completer = Completer<void>.sync();
  transaction.oncomplete = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  transaction.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(const WebJournalStorageException());
    }
  }).toJS;
  transaction.onabort = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(const WebJournalStorageException());
    }
  }).toJS;
  final completed = completer.future;
  // A request can fail before the caller reaches its catch block. Register an
  // error listener immediately while preserving the error for awaited callers.
  unawaited(completed.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
  return completed;
}

Future<void> _ignoreAbort(Future<void> completed) async {
  try {
    await completed;
  } on WebJournalStorageException {
    // An explicit optimistic-concurrency abort is expected here.
  }
}

BigInt _parsePosition(JSAny? value, {required bool allowZero}) {
  final source = value?.dartify();
  if (source is! String) throw const WebJournalIntegrityException();
  final parsed = BigInt.tryParse(source);
  final minimum = allowZero ? BigInt.zero : BigInt.one;
  if (parsed == null ||
      parsed.toString() != source ||
      parsed < minimum ||
      parsed > BigInt.parse('9223372036854775807')) {
    throw const WebJournalIntegrityException();
  }
  return parsed;
}

String _positionKey(BigInt position) {
  if (position < BigInt.one || position > BigInt.parse('9223372036854775807')) {
    throw ArgumentError.value(position, 'position', 'Outside signed int64.');
  }
  return position.toString().padLeft(19, '0');
}

Map<String, Object?> _dartMap(JSAny? value) {
  final dart = value?.dartify();
  if (dart is! Map<Object?, Object?>) {
    throw const WebJournalIntegrityException();
  }
  final result = <String, Object?>{};
  for (final entry in dart.entries) {
    if (entry.key is! String) throw const WebJournalIntegrityException();
    result[entry.key! as String] = entry.value;
  }
  return result;
}

List<int> _arrayBufferBytes(JSAny? value) {
  final buffer = value as JSArrayBuffer;
  return Uint8List.view(buffer.toDart);
}

bool _readMarker(String databaseName) {
  try {
    return web.window.localStorage.getItem(
          '${BrowserEncryptedJournalPrototype._markerPrefix}$databaseName',
        ) ==
        '1';
  } on Object {
    throw const WebJournalStorageException();
  }
}

void _writeMarker(String databaseName) {
  try {
    web.window.localStorage.setItem(
      '${BrowserEncryptedJournalPrototype._markerPrefix}$databaseName',
      '1',
    );
  } on Object {
    throw const WebJournalStorageException();
  }
}
