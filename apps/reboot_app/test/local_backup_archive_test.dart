import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/infrastructure/local_backup_archive.dart';
import 'package:reboot_app/infrastructure/local_profile_bootstrap.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_storage/reboot_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reboot-backup-test-');
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('recovery code round-trips exactly 256 bits', () {
    final source = Uint8List.fromList(List<int>.generate(32, (index) => index));
    final encoded = LocalBackupRecoveryCode.encode(source);

    expect(encoded, startsWith('RB1.'));
    expect(LocalBackupRecoveryCode.decode('  $encoded\n'), source);
    expect(
      () => LocalBackupRecoveryCode.decode('RB2.invalid'),
      throwsA(isA<LocalBackupException>()),
    );
  });

  test('exports an opaque archive and restores its immutable events', () async {
    final source = await _configuredService();
    final destination = await LocalRebootService.restore(
      journal: _MemoryJournal(),
    );
    final manager = _manager(directory, byte: 77);

    final backup = await manager.prepare(source);
    final bytes = await backup.file.readAsBytes();
    final sourceSnapshot = await source.readJournalSnapshot();

    expect(
      utf8.decode(bytes, allowMalformed: true),
      isNot(contains('household')),
    );
    expect(
      LocalBackupRecoveryCode.decode(backup.recoveryCode),
      everyElement(77),
    );
    await manager.restore(
      destination: destination,
      file: backup.file,
      recoveryCode: backup.recoveryCode,
    );
    final restored = await destination.readJournalSnapshot();
    expect(
      restored.map((entry) => entry.event.id),
      sourceSnapshot.map((entry) => entry.event.id),
    );
    expect(destination.configuration.household, isNotNull);

    await manager.discard(backup);
    expect(await backup.file.exists(), isFalse);
    await source.close();
    await destination.close();
  });

  test('wrong code and non-empty destination both fail closed', () async {
    final source = await _configuredService();
    final manager = _manager(directory, byte: 33);
    final backup = await manager.prepare(source);
    final wrongCode = LocalBackupRecoveryCode.encode(
      Uint8List.fromList(List<int>.filled(32, 34)),
    );

    await expectLater(
      manager.read(file: backup.file, recoveryCode: wrongCode),
      throwsA(
        isA<LocalBackupException>().having(
          (error) => error.reason,
          'reason',
          LocalBackupFailureReason.archiveInvalid,
        ),
      ),
    );
    final destination = await _configuredService();
    final original = await destination.readJournalSnapshot();
    await expectLater(
      manager.restore(
        destination: destination,
        file: backup.file,
        recoveryCode: backup.recoveryCode,
      ),
      throwsA(
        isA<LocalBackupException>().having(
          (error) => error.reason,
          'reason',
          LocalBackupFailureReason.localProfileNotEmpty,
        ),
      ),
    );
    expect(await destination.readJournalSnapshot(), original);

    await manager.discard(backup);
    await source.close();
    await destination.close();
  });
}

LocalBackupArchiveService _manager(Directory directory, {required int byte}) {
  return LocalBackupArchiveService(
    temporaryDirectory: () async => directory,
    keyGenerator: _FixedKeyGenerator(byte),
    openJournal: (filePath, key) =>
        RebootEventJournal.open(filePath: filePath, key: key),
  );
}

Future<LocalRebootService> _configuredService() async {
  final service = await LocalRebootService.restore(journal: _MemoryJournal());
  await service.initializeHousehold(
    InitializeHouseholdCommand(
      householdKind: HouseholdKind.sharedMainAccount,
      onboardingDate: LocalDate(2026, 4, 1),
      anchorWeekday: Weekday.saturday,
      timeZone: IanaTimeZoneId('Europe/Paris'),
      firstCycleChoice: FirstCycleStartChoice.nextAnchor,
    ),
  );
  return service;
}

final class _FixedKeyGenerator implements DatabaseKeyMaterialGenerator {
  const _FixedKeyGenerator(this.byte);

  final int byte;

  @override
  Uint8List generate() => Uint8List.fromList(List<int>.filled(32, byte));
}

final class _MemoryJournal implements LocalEventJournal {
  final List<LocalJournalEntry> entries = [];

  @override
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events) async {
    final appended = <LocalJournalEntry>[];
    for (final event in events) {
      final entry = LocalJournalEntry(
        position: LocalJournalPosition(entries.length + 1),
        event: event,
      );
      entries.add(entry);
      appended.add(entry);
    }
    return appended;
  }

  @override
  Future<void> close() async {}

  @override
  Future<List<LocalJournalEntry>> readAll() async => List.of(entries);
}
