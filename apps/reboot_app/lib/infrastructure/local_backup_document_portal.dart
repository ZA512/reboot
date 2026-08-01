import 'dart:io';

import 'package:flutter/services.dart';

/// System document-picker boundary for encrypted local backups.
abstract interface class LocalBackupDocumentPortal {
  /// Lets the user copy an already closed private archive to one destination.
  Future<bool> save({required File source, required String suggestedName});

  /// Copies a selected document into private temporary storage.
  Future<File?> pick();

  /// Copies a recovery code while asking Android to hide clipboard previews.
  Future<void> copySensitive(String recoveryCode);
}

/// Android Storage Access Framework implementation without broad file access.
final class AndroidLocalBackupDocumentPortal
    implements LocalBackupDocumentPortal {
  const AndroidLocalBackupDocumentPortal({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.za512.reboot/local_backup';
  final MethodChannel _channel;

  @override
  Future<bool> save({
    required File source,
    required String suggestedName,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('saveBackup', {
            'sourcePath': source.absolute.path,
            'suggestedName': suggestedName,
          }) ??
          false;
    } on PlatformException catch (error) {
      throw LocalBackupDocumentException(_reason(error.code));
    }
  }

  @override
  Future<File?> pick() async {
    try {
      final path = await _channel.invokeMethod<String>('pickBackup');
      return path == null ? null : File(path);
    } on PlatformException catch (error) {
      throw LocalBackupDocumentException(_reason(error.code));
    }
  }

  @override
  Future<void> copySensitive(String recoveryCode) async {
    try {
      await _channel.invokeMethod<void>('copyRecoveryCode', {
        'code': recoveryCode,
      });
    } on PlatformException catch (error) {
      throw LocalBackupDocumentException(_reason(error.code));
    }
  }
}

final class LocalBackupDocumentException implements Exception {
  const LocalBackupDocumentException(this.reason);

  final LocalBackupDocumentFailureReason reason;
}

enum LocalBackupDocumentFailureReason { busy, tooLarge, unavailable }

LocalBackupDocumentFailureReason _reason(String code) => switch (code) {
  'backup_busy' => LocalBackupDocumentFailureReason.busy,
  'backup_too_large' => LocalBackupDocumentFailureReason.tooLarge,
  _ => LocalBackupDocumentFailureReason.unavailable,
};
