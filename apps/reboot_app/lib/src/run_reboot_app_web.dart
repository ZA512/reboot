import 'package:flutter/material.dart';

import 'web_prototype_app.dart';

/// Starts only the non-persistent Web shell until storage is proven safe.
void runRebootApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WebPrototypeApp());
}
