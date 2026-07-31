# reboot_domain

Pure Dart values, invariants and business events for REBOOT.

This package must not depend on Flutter, storage, the system clock or the
network.

Implemented foundations:

- exact signed 64-bit `Money` values;
- explicit supported ISO 4217 currencies;
- checked arithmetic and exact installment allocation;
- local civil dates and auditable weekly-cycle policies;
- explicit short or long transitions when the anchor weekday changes.
