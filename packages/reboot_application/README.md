# reboot_application

Pure Dart commands, use cases and infrastructure ports for REBOOT.

This package orchestrates the domain and projection engine without depending
on Flutter or a concrete infrastructure implementation.

`LocalRebootService` owns one local event journal and exposes the first command
boundary used by the mobile application:

- initialize the solo or shared household and its first REBOOT cycle;
- create, replace, and delete fixed or variable cash-flow assumptions;
- set annual reserve, project, and safety commitments;
- create, confirm, and stop already-received bonus pools without forecasting a
  future payment;
- schedule a new REBOOT day or time zone without rewriting history;
- calculate the explainable 52-cycle weekly recommendation;
- record and atomically allocate an expense over 1 to 12 cycles;
- tombstone a mistaken expense and all of its allocations.

Commands are serialized, validated against the pure projections before append,
and restored solely by replaying the journal. UTC time and UUID v7 generation
are injectable ports so tests never depend on the wall clock or random IDs.
