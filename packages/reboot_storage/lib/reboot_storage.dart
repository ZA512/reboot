/// Encrypted local persistence adapters for REBOOT.
library;

export 'src/database.dart'
    show
        EncryptedDatabaseKey,
        EncryptedStorageFailureReason,
        EncryptedStorageOpenException;
export 'src/event_journal.dart'
    show JournalEventConflictException, RebootEventJournal;
