import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reboot_app.dart';

/// Starts the native composition with its encrypted SQLite profile.
void runRebootApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RebootApp()));
}
