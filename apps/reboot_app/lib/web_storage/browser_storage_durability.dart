import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browser storage status that must be shown before real Web data is enabled.
final class WebStorageDurabilityStatus {
  const WebStorageDurabilityStatus({
    required this.isPersistent,
    required this.usageBytes,
    required this.quotaBytes,
  });

  final bool isPersistent;
  final int usageBytes;
  final int quotaBytes;

  bool get isBestEffort => !isPersistent;
}

/// Reads the origin quota and optionally asks the browser not to evict it.
///
/// A refusal is a valid best-effort result. An unavailable or incoherent API
/// fails closed instead of pretending that browser storage is durable.
Future<WebStorageDurabilityStatus> inspectWebStorageDurability({
  bool requestPersistence = false,
}) async {
  try {
    final storage = web.window.navigator.storage;
    var persistent = (await storage.persisted().toDart).toDart;
    if (!persistent && requestPersistence) {
      persistent = (await storage.persist().toDart).toDart;
    }
    final estimate = await storage.estimate().toDart;
    final usage = estimate.usage;
    final quota = estimate.quota;
    if (usage < 0 || quota <= 0 || usage > quota) {
      throw const WebStorageDurabilityException();
    }
    return WebStorageDurabilityStatus(
      isPersistent: persistent,
      usageBytes: usage,
      quotaBytes: quota,
    );
  } on WebStorageDurabilityException {
    rethrow;
  } on Object {
    throw const WebStorageDurabilityException();
  }
}

/// Sanitized failure raised when browser durability cannot be established.
final class WebStorageDurabilityException implements Exception {
  const WebStorageDurabilityException();

  @override
  String toString() => 'WebStorageDurabilityException';
}
