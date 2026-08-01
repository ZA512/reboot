import 'src/run_reboot_app_native.dart'
    if (dart.library.js_interop) 'src/run_reboot_app_web.dart';

void main() => runRebootApp();
