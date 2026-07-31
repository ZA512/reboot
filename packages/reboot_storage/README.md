# reboot_storage

Encrypted local SQLite storage for REBOOT.

This package implements application persistence ports with Drift and the
SQLite3MultipleCiphers build supplied by `package:sqlite3`. It must fail closed
when encryption support or the exact database key is unavailable.

The package owns the versioned, append-only event journal. It deliberately
does not obtain keys from platform secure storage: the Flutter composition root
must provide an absolute private file path and an exact 256-bit key.

From this directory, regenerate checked-in Drift artifacts with:

```shell
dart run build_runner build
dart run drift_dev make-migrations
```

`drift_schemas/` is part of the source history. Every future schema change must
increment `schemaVersion`, add explicit migration steps, and retain migration
tests for all published versions.
