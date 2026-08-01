@TestOn('browser')
library;

import 'package:reboot_app/web_storage/browser_storage_durability.dart';
import 'package:test/test.dart';

void main() {
  test('reports an explicit persistent or best-effort browser quota', () async {
    final status = await inspectWebStorageDurability(requestPersistence: true);

    expect(status.usageBytes, greaterThanOrEqualTo(0));
    expect(status.quotaBytes, greaterThan(0));
    expect(status.usageBytes, lessThanOrEqualTo(status.quotaBytes));
    expect(status.isBestEffort, isNot(status.isPersistent));
  });
}
