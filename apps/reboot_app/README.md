# REBOOT application

Flutter application for native Android and the future Web/PWA client. Android
is the current implementation target. The Web target will be enabled only
after its encrypted local storage and key custody prototype is validated.

Business rules and financial calculations belong to the pure Dart workspace
packages, never to widgets.

The Android flow currently covers onboarding, recurring assumptions,
trajectory, weekly spending, reserves, refunds, optional health tracking,
cycle settings, and received bonus pools that require confirmation at their
next payment date. Its Android home-screen widget stores only an encrypted,
already-formatted remaining amount, masks it by default, and reveals it for two
seconds on demand.

REBOOT weekly remaining-to-live budget application.
