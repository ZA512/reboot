import 'dart:convert';
import 'dart:io';

final String _root = Directory.current.absolute.path;

Future<void> main() async {
  await _verifyToolchain();
  await _run(Platform.resolvedExecutable, const [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    '.',
  ]);
  await _run(Platform.resolvedExecutable, const ['analyze', '--fatal-infos']);

  for (final package in [
    'packages/reboot_domain',
    'packages/reboot_projection',
    'packages/reboot_application',
    'packages/reboot_storage',
  ]) {
    await _runTestsWhenPresent(
      executable: Platform.resolvedExecutable,
      package: package,
    );
  }

  await _runTestsWhenPresent(
    executable: _flutterExecutable(),
    package: 'apps/reboot_app',
  );
}

Future<void> _runTestsWhenPresent({
  required String executable,
  required String package,
}) async {
  final workingDirectory = Directory('$_root${Platform.pathSeparator}$package');
  final tests = Directory(
    '${workingDirectory.path}${Platform.pathSeparator}test',
  );

  if (!tests.existsSync()) {
    stdout.writeln('No tests yet in $package; skipping.');
    return;
  }

  await _run(executable, const [
    'test',
  ], workingDirectory: workingDirectory.path);
}

String _flutterExecutable() {
  final dartExecutable = File(Platform.resolvedExecutable);
  final flutterBin = dartExecutable.parent.parent.parent.parent;
  final executableName = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final bundledFlutter = File(
    '${flutterBin.path}${Platform.pathSeparator}$executableName',
  );

  return bundledFlutter.existsSync() ? bundledFlutter.path : executableName;
}

Future<void> _verifyToolchain() async {
  final manifest =
      jsonDecode(
            await File(
              '$_root${Platform.pathSeparator}tool'
              '${Platform.pathSeparator}flutter-version.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  final expected = manifest['flutter'] as Map<String, dynamic>;
  final result = await Process.run(
    _flutterExecutable(),
    const ['--version', '--machine'],
    workingDirectory: _root,
    runInShell: Platform.isWindows,
  );

  if (result.exitCode != 0) {
    throw ProcessException(
      _flutterExecutable(),
      const ['--version', '--machine'],
      result.stderr.toString(),
      result.exitCode,
    );
  }

  final actual = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
  final mismatches = <String>[
    if (actual['flutterVersion'] != expected['version'])
      'Flutter ${actual['flutterVersion']} != ${expected['version']}',
    if (actual['frameworkRevision'] != expected['revision'])
      'revision ${actual['frameworkRevision']} != ${expected['revision']}',
    if (actual['dartSdkVersion'] != expected['dart'])
      'Dart ${actual['dartSdkVersion']} != ${expected['dart']}',
  ];

  if (mismatches.isNotEmpty) {
    throw StateError('Unexpected toolchain: ${mismatches.join(', ')}');
  }

  stdout.writeln(
    'Toolchain verified: Flutter ${expected['version']}, '
    'Dart ${expected['dart']}.',
  );
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  stdout.writeln(
    '> $executable ${arguments.join(' ')}'
    '${workingDirectory == null ? '' : ' ($workingDirectory)'}',
  );

  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory ?? _root,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows && executable.endsWith('.bat'),
  );
  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    throw ProcessException(executable, arguments, '', exitCode);
  }
}
