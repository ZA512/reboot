import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'web_prototype_app.dart';

/// Starts only the non-persistent Web shell until storage is proven safe.
void runRebootApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    WebPrototypeApp(
      isStandalone: web.window.matchMedia('(display-mode: standalone)').matches,
    ),
  );
}
