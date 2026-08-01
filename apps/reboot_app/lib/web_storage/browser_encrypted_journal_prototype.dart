import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'encrypted_event_envelope.dart';

/// Browser-only proof that clear event payloads never enter IndexedDB.
///
/// This class is deliberately not wired to the production application port.
final class BrowserEncryptedJournalPrototype {
  BrowserEncryptedJournalPrototype._({
    required this._database,
    required this._dataKey,
    required this.databaseName,
  });

  static const int schemaVersion = 1;
  static const String _keyStore = 'keys';
  static const String _metadataStore = 'metadata';
  static const String _entryStore = 'entries';
  static const String _eventIdStore = 'event_ids';
  static const String _initializedKey = 'initialized';
  static const String _lastPositionKey = 'last_position';
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
        if (key.extractable || key.type != 'secret') {
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
    final values = await _readAllValues(_database, _entryStore);
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

  /// Returns opaque persisted records for confidentiality assertions only.
  Future<List<Map<String, Object?>>> inspectEncryptedRecordsForTesting() async {
    _ensureOpen();
    final values = await _readAllValues(_database, _entryStore);
    return List<Map<String, Object?>>.unmodifiable(values.map(_dartMap));
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

  void _ensureOpen() {
    if (_closed) throw StateError('The prototype journal is closed.');
  }
}

enum _CommitResult { committed, retry }

({web.IDBDatabase database, bool created}) _openedResult(
  web.IDBOpenDBRequest request,
  bool created,
) => (database: request.result as web.IDBDatabase, created: created);

Future<({web.IDBDatabase database, bool created})> _openDatabase(String name) {
  final completer = Completer<({web.IDBDatabase database, bool created})>();
  final request = web.window.indexedDB.open(
    name,
    BrowserEncryptedJournalPrototype.schemaVersion,
  );
  var created = false;
  request.onupgradeneeded = ((web.Event _) {
    created = true;
    final database = request.result as web.IDBDatabase;
    database.createObjectStore(BrowserEncryptedJournalPrototype._keyStore);
    database.createObjectStore(BrowserEncryptedJournalPrototype._metadataStore);
    database.createObjectStore(BrowserEncryptedJournalPrototype._entryStore);
    database.createObjectStore(BrowserEncryptedJournalPrototype._eventIdStore);
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
    if (key.extractable || key.type != 'secret') {
      throw const WebJournalStorageException();
    }
    return key;
  } on WebJournalStorageException {
    rethrow;
  } on Object {
    throw const WebJournalStorageException();
  }
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
