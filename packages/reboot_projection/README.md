# reboot_projection

Pure Dart calculations and deterministic projections for REBOOT.

This package may depend on `reboot_domain`, but not on Flutter, persistence,
the system clock or the network.

Implemented foundations:

- deterministic expense replay ordered by local journal position;
- UUID-based idempotence;
- explicit expense tombstones that preserve audit history;
- exact overlapping allocations and a gap-free rolling 52-cycle projection.
