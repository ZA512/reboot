import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:reboot_app/infrastructure/local_profile_bootstrap.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_storage/reboot_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'reboot-profile-bootstrap-test-',
    );
  });

  tearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  test('creates and stores one key before opening a new profile', () async {
    final secureValues = _MemorySecureValues();
    final generator = _FixedKeyGenerator(7);
    final opener = _CapturingJournalOpener();
    final bootstrap = _bootstrap(
      directory: directory,
      secureValues: secureValues,
      generator: generator,
      opener: opener.call,
    );

    final service = await bootstrap.open();

    expect(generator.callCount, 1);
    expect(opener.callCount, 1);
    expect(path.isAbsolute(opener.path!), isTrue);
    expect(opener.path, endsWith('reboot-profile-v1.db'));
    expect(opener.keyBytes, everyElement(7));
    expect(
      base64Url.decode(secureValues.values.values.single),
      everyElement(7),
    );
    expect(opener.keyWrapper!.copyBytes, throwsStateError);
    expect(service.configuration.household, isNull);
    await service.close();
  });

  test('reuses a valid stored key without generating another', () async {
    final secureValues = _MemorySecureValues()
      ..values['profile.default.database-key.v1'] = base64UrlEncode(
        Uint8List.fromList(List<int>.filled(32, 11)),
      );
    final generator = _FixedKeyGenerator(7);
    final opener = _CapturingJournalOpener();

    final service = await _bootstrap(
      directory: directory,
      secureValues: secureValues,
      generator: generator,
      opener: opener.call,
    ).open();

    expect(generator.callCount, 0);
    expect(opener.keyBytes, everyElement(11));
    await service.close();
  });

  test(
    'never replaces a missing key when an encrypted database exists',
    () async {
      final database = File(
        '${directory.path}${Platform.pathSeparator}reboot-profile-v1.db',
      );
      await database.writeAsBytes(const [1, 2, 3], flush: true);
      final generator = _FixedKeyGenerator(7);
      final opener = _CapturingJournalOpener();

      expect(
        () => _bootstrap(
          directory: directory,
          secureValues: _MemorySecureValues(),
          generator: generator,
          opener: opener.call,
        ).open(),
        throwsA(
          isA<LocalProfileOpenException>().having(
            (error) => error.reason,
            'reason',
            LocalProfileOpenFailureReason.missingKeyForExistingDatabase,
          ),
        ),
      );
      expect(generator.callCount, 0);
      expect(opener.callCount, 0);
      expect(await database.readAsBytes(), [1, 2, 3]);
    },
  );

  test(
    'rejects malformed stored key material without overwriting it',
    () async {
      final secureValues = _MemorySecureValues()
        ..values['profile.default.database-key.v1'] = 'not-base64%%%';
      final original = Map<String, String>.of(secureValues.values);
      final opener = _CapturingJournalOpener();

      expect(
        () => _bootstrap(
          directory: directory,
          secureValues: secureValues,
          generator: _FixedKeyGenerator(7),
          opener: opener.call,
        ).open(),
        throwsA(
          isA<LocalProfileOpenException>().having(
            (error) => error.reason,
            'reason',
            LocalProfileOpenFailureReason.invalidKeyMaterial,
          ),
        ),
      );
      expect(secureValues.values, original);
      expect(opener.callCount, 0);
    },
  );

  test('sanitizes secure-store failures and does not open SQLite', () async {
    final opener = _CapturingJournalOpener();

    expect(
      () => _bootstrap(
        directory: directory,
        secureValues: _ThrowingSecureValues(),
        generator: _FixedKeyGenerator(7),
        opener: opener.call,
      ).open(),
      throwsA(
        isA<LocalProfileOpenException>().having(
          (error) => error.reason,
          'reason',
          LocalProfileOpenFailureReason.secureStorageUnavailable,
        ),
      ),
    );
    expect(opener.callCount, 0);
  });
}

LocalProfileBootstrap _bootstrap({
  required Directory directory,
  required SecureValueStore secureValues,
  required DatabaseKeyMaterialGenerator generator,
  required LocalJournalOpener opener,
}) {
  return LocalProfileBootstrap(
    secureValues: secureValues,
    supportDirectory: () async => directory,
    keyGenerator: generator,
    openJournal: opener,
  );
}

final class _MemorySecureValues implements SecureValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

final class _ThrowingSecureValues implements SecureValueStore {
  @override
  Future<String?> read(String key) {
    throw StateError('sensitive platform detail');
  }

  @override
  Future<void> write(String key, String value) {
    throw StateError('sensitive platform detail');
  }
}

final class _FixedKeyGenerator implements DatabaseKeyMaterialGenerator {
  _FixedKeyGenerator(this.byte);

  final int byte;
  int callCount = 0;

  @override
  Uint8List generate() {
    callCount++;
    return Uint8List.fromList(List<int>.filled(32, byte));
  }
}

final class _CapturingJournalOpener {
  int callCount = 0;
  String? path;
  Uint8List? keyBytes;
  EncryptedDatabaseKey? keyWrapper;

  Future<LocalEventJournal> call(
    String filePath,
    EncryptedDatabaseKey key,
  ) async {
    callCount++;
    path = filePath;
    keyBytes = key.copyBytes();
    keyWrapper = key;
    return _MemoryJournal();
  }
}

final class _MemoryJournal implements LocalEventJournal {
  @override
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events) async {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}

  @override
  Future<List<LocalJournalEntry>> readAll() async => const [];
}
