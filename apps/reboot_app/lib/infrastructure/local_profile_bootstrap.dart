import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_storage/reboot_storage.dart';

/// Minimal string-secret boundary implemented by the platform Keychain or
/// Keystore adapter in production.
abstract interface class SecureValueStore {
  /// Reads one namespaced secret, or `null` when no profile exists yet.
  Future<String?> read(String key);

  /// Persists one namespaced secret before creating dependent data.
  Future<void> write(String key, String value);
}

/// Explicit platform configuration required by the key-lifecycle ADR.
final class FlutterSecureValueStore implements SecureValueStore {
  /// Creates the production Keychain and Keystore adapter.
  FlutterSecureValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const AndroidOptions _androidOptions = AndroidOptions(
    resetOnError: false,
    // The plugin also uses this path on a fresh install without algorithm
    // markers. Migration preserves an existing secret; resetOnError remains
    // false so a failed migration can never replace or delete it silently.
    migrateOnAlgorithmChange: true,
    migrateWithBackup: false,
    keyCipherAlgorithm:
        KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    storageNamespace: 'reboot_local_secrets_v1',
  );
  static const IOSOptions _iosOptions = IOSOptions(
    accountName: 'com.za512.reboot.local-secrets.v1',
    accessibility: KeychainAccessibility.unlocked_this_device,
    synchronizable: false,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) {
    return _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}

/// Supplies fresh local database key material.
abstract interface class DatabaseKeyMaterialGenerator {
  /// Returns exactly 256 random bits.
  Uint8List generate();
}

/// Operating-system CSPRNG adapter for the installation-local database key.
final class SecureDatabaseKeyMaterialGenerator
    implements DatabaseKeyMaterialGenerator {
  /// Creates a generator backed by `Random.secure`.
  SecureDatabaseKeyMaterialGenerator() : _random = Random.secure();

  final Random _random;

  @override
  Uint8List generate() {
    return Uint8List.fromList(
      List<int>.generate(32, (_) => _random.nextInt(256)),
    );
  }
}

/// Opens the concrete local event journal with one transient key wrapper.
typedef LocalJournalOpener =
    Future<LocalEventJournal> Function(
      String filePath,
      EncryptedDatabaseKey key,
    );

/// Fail-closed bootstrap for one installation-local encrypted profile.
final class LocalProfileBootstrap {
  /// Creates a bootstrap whose boundaries can all be replaced in tests.
  const LocalProfileBootstrap({
    required this.secureValues,
    required this.supportDirectory,
    required this.keyGenerator,
    required this.openJournal,
  });

  static const String _databaseKeyName = 'profile.default.database-key.v1';
  static const String _databaseFilename = 'reboot-profile-v1.db';

  /// Platform secure-value adapter.
  final SecureValueStore secureValues;

  /// Private application-support directory resolver.
  final Future<Directory> Function() supportDirectory;

  /// Fresh 256-bit material generator.
  final DatabaseKeyMaterialGenerator keyGenerator;

  /// Encrypted journal factory.
  final LocalJournalOpener openJournal;

  /// Opens an existing profile or creates a new empty one safely.
  Future<LocalRebootService> open() async {
    final Directory directory;
    try {
      directory = await supportDirectory();
      await directory.create(recursive: true);
    } on Object {
      throw const LocalProfileOpenException(
        LocalProfileOpenFailureReason.privateDirectoryUnavailable,
      );
    }
    final databasePath = path.join(directory.absolute.path, _databaseFilename);
    final databaseExists = await File(databasePath).exists();

    final String? encodedKey;
    try {
      encodedKey = await secureValues.read(_databaseKeyName);
    } on Object {
      throw const LocalProfileOpenException(
        LocalProfileOpenFailureReason.secureStorageUnavailable,
      );
    }

    final Uint8List keyBytes;
    if (encodedKey == null) {
      if (databaseExists) {
        throw const LocalProfileOpenException(
          LocalProfileOpenFailureReason.missingKeyForExistingDatabase,
        );
      }
      keyBytes = keyGenerator.generate();
      if (keyBytes.length != 32) {
        keyBytes.fillRange(0, keyBytes.length, 0);
        throw const LocalProfileOpenException(
          LocalProfileOpenFailureReason.invalidKeyMaterial,
        );
      }
      try {
        await secureValues.write(_databaseKeyName, base64UrlEncode(keyBytes));
      } on Object {
        keyBytes.fillRange(0, keyBytes.length, 0);
        throw const LocalProfileOpenException(
          LocalProfileOpenFailureReason.secureStorageUnavailable,
        );
      }
    } else {
      try {
        keyBytes = base64Url.decode(encodedKey);
      } on Object {
        throw const LocalProfileOpenException(
          LocalProfileOpenFailureReason.invalidKeyMaterial,
        );
      }
      if (keyBytes.length != 32) {
        keyBytes.fillRange(0, keyBytes.length, 0);
        throw const LocalProfileOpenException(
          LocalProfileOpenFailureReason.invalidKeyMaterial,
        );
      }
    }

    final key = EncryptedDatabaseKey(keyBytes);
    keyBytes.fillRange(0, keyBytes.length, 0);
    final LocalEventJournal journal;
    try {
      journal = await openJournal(databasePath, key);
    } on Object {
      throw const LocalProfileOpenException(
        LocalProfileOpenFailureReason.encryptedDatabaseUnavailable,
      );
    } finally {
      key.destroy();
    }

    try {
      return await LocalRebootService.restore(journal: journal);
    } on Object {
      await journal.close();
      throw const LocalProfileOpenException(
        LocalProfileOpenFailureReason.invalidJournal,
      );
    }
  }
}

/// Sanitized profile-open categories safe to expose to presentation code.
enum LocalProfileOpenFailureReason {
  /// The private application directory could not be prepared.
  privateDirectoryUnavailable,

  /// The platform secure store could not read or persist its value.
  secureStorageUnavailable,

  /// An encrypted database exists but its installation key is absent.
  missingKeyForExistingDatabase,

  /// Stored or generated key material is not one exact 256-bit value.
  invalidKeyMaterial,

  /// The encrypted database rejected its engine, key, settings, or schema.
  encryptedDatabaseUnavailable,

  /// Persisted events cannot rebuild valid projections.
  invalidJournal,
}

/// Fail-closed error containing no path, key, event, label, or amount.
final class LocalProfileOpenException implements Exception {
  /// Creates a sanitized profile-open failure.
  const LocalProfileOpenException(this.reason);

  /// Non-sensitive failure category.
  final LocalProfileOpenFailureReason reason;

  @override
  String toString() => 'LocalProfileOpenException: ${reason.name}';
}
