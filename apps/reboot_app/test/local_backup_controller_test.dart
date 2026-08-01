import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/infrastructure/local_backup_archive.dart';
import 'package:reboot_app/infrastructure/local_backup_document_portal.dart';
import 'package:reboot_app/settings/local_backup_controller.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'reboot-backup-controller-test-',
    );
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('exports, saves, and discards one temporary archive', () async {
    final archive = _FakeArchive(directory: directory);
    final portal = _FakePortal();
    final container = ProviderContainer(
      overrides: [
        localBackupArchiveServiceProvider.overrideWithValue(archive),
        localBackupDocumentPortalProvider.overrideWithValue(portal),
      ],
    );
    addTearDown(container.dispose);
    final service = await _configuredService();

    final code = await container
        .read(localBackupControllerProvider.notifier)
        .export(
          service: service,
          suggestedName: 'reboot-2026-08-01.reboot-backup',
        );

    expect(code, 'RB1.test-recovery-code');
    expect(portal.savedName, 'reboot-2026-08-01.reboot-backup');
    expect(archive.discarded, isTrue);
    expect(container.read(localBackupControllerProvider).hasError, isFalse);
    await service.close();
  });

  test(
    'restores selected events and deletes the private selected copy',
    () async {
      final source = await _configuredService();
      final snapshot = await source.readJournalSnapshot();
      final selected = File(
        '${directory.path}${Platform.pathSeparator}selected.backup',
      );
      await selected.writeAsBytes(const [1], flush: true);
      final archive = _FakeArchive(
        directory: directory,
        restoreSnapshot: snapshot,
      );
      final portal = _FakePortal()..selected = selected;
      final container = ProviderContainer(
        overrides: [
          localBackupArchiveServiceProvider.overrideWithValue(archive),
          localBackupDocumentPortalProvider.overrideWithValue(portal),
        ],
      );
      addTearDown(container.dispose);
      final destination = await LocalRebootService.restore(
        journal: _MemoryJournal(),
      );

      final restored = await container
          .read(localBackupControllerProvider.notifier)
          .restore(
            service: destination,
            recoveryCode: 'RB1.test-recovery-code',
          );

      expect(restored, isTrue);
      expect(destination.configuration.household, isNotNull);
      expect(await selected.exists(), isFalse);
      expect(container.read(localBackupControllerProvider).hasError, isFalse);
      await source.close();
      await destination.close();
    },
  );
}

final class _FakeArchive implements LocalBackupArchive {
  _FakeArchive({required this.directory, this.restoreSnapshot});

  final Directory directory;
  final List<LocalJournalEntry>? restoreSnapshot;
  bool discarded = false;

  @override
  Future<void> discard(PreparedLocalBackup backup) async {
    discarded = true;
  }

  @override
  Future<PreparedLocalBackup> prepare(LocalRebootService service) async {
    return PreparedLocalBackup(
      file: File('${directory.path}${Platform.pathSeparator}prepared.backup'),
      recoveryCode: 'RB1.test-recovery-code',
    );
  }

  @override
  Future<void> restore({
    required LocalRebootService destination,
    required File file,
    required String recoveryCode,
  }) async {
    await destination.restoreJournalSnapshot(restoreSnapshot!);
  }
}

final class _FakePortal implements LocalBackupDocumentPortal {
  File? selected;
  String? savedName;

  @override
  Future<void> copySensitive(String recoveryCode) async {}

  @override
  Future<File?> pick() async => selected;

  @override
  Future<bool> save({
    required File source,
    required String suggestedName,
  }) async {
    savedName = suggestedName;
    return true;
  }
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
