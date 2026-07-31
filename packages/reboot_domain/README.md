# reboot_domain

Pure Dart values, invariants and business events for REBOOT.

This package must not depend on Flutter, storage, the system clock or the
network.

Implemented foundations:

- exact signed 64-bit `Money` values;
- explicit supported ISO 4217 currencies;
- checked arithmetic and exact installment allocation;
- local civil dates and auditable weekly-cycle policies;
- explicit short or long transitions when the anchor weekday changes;
- fixed and variable cash flows with civil recurrence schedules;
- already-received bonus pools that cannot include future expected money;
- versioned household, cycle-policy, cash-flow, and commitment events;
- immutable, versioned expense events and separate local journal positions.
