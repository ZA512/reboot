# reboot_projection

Pure Dart calculations and deterministic projections for REBOOT.

This package may depend on `reboot_domain`, but not on Flutter, persistence,
the system clock or the network.

Implemented foundations:

- deterministic expense replay ordered by local journal position;
- UUID-based idempotence;
- explicit expense tombstones that preserve audit history;
- exact overlapping allocations and a gap-free rolling 52-cycle projection;
- exact-date annualization of fixed and variable incomes and outflows;
- prudent 90% income and 110% outflow estimates with deterministic rounding;
- whole-euro weekly recommendations with the retained annual margin exposed;
- exact allocation of already-received bonus pools until their renewal date;
- replayable household configuration with future-effective replacements and
  tombstones;
- annual recommendations rebuilt directly from the shared global journal.
