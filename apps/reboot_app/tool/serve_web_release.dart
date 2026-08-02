import 'dart:io';

import 'web_hosting_contract.dart';

const int _defaultPort = 8788;

Future<void> main(List<String> arguments) async {
  final port = _readPort(arguments);
  final projectDirectory = Directory.current.absolute;
  final buildDirectory = Directory(
    '${projectDirectory.path}${Platform.pathSeparator}build'
    '${Platform.pathSeparator}web',
  );
  final headersFile = File(
    '${buildDirectory.path}${Platform.pathSeparator}_headers',
  );
  if (!headersFile.existsSync()) {
    throw StateError(
      'Prepare the Web release before serving it: '
      'dart run tool/build_web_release.dart',
    );
  }

  final contract = WebHostingContract.parse(await headersFile.readAsString());
  contract.validate();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln(
    'Serving the validated REBOOT Web release at http://127.0.0.1:$port/',
  );

  await for (final request in server) {
    await _serve(request, buildDirectory, contract);
  }
}

int _readPort(List<String> arguments) {
  if (arguments.isEmpty) {
    return _defaultPort;
  }
  if (arguments.length != 1 || !arguments.single.startsWith('--port=')) {
    throw const FormatException('Expected only --port=<1..65535>.');
  }
  final port = int.tryParse(arguments.single.substring('--port='.length));
  if (port == null || port < 1 || port > 65535) {
    throw const FormatException('Expected only --port=<1..65535>.');
  }
  return port;
}

Future<void> _serve(
  HttpRequest request,
  Directory buildDirectory,
  WebHostingContract contract,
) async {
  final routePath = request.uri.path;
  for (final entry in contract.headersFor(routePath).entries) {
    request.response.headers.set(entry.key, entry.value);
  }

  if (request.method != 'GET' && request.method != 'HEAD') {
    request.response
      ..statusCode = HttpStatus.methodNotAllowed
      ..headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
    await request.response.close();
    return;
  }

  final relativePath = _safeRelativePath(routePath);
  if (relativePath == null || relativePath == '_headers') {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
    return;
  }

  final file = File(
    '${buildDirectory.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  if (!file.existsSync()) {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
    return;
  }

  request.response.headers.contentType = _contentTypeFor(relativePath);
  request.response.contentLength = await file.length();
  if (request.method == 'GET') {
    await request.response.addStream(file.openRead());
  }
  await request.response.close();
}

String? _safeRelativePath(String routePath) {
  final decoded = Uri.decodeComponent(routePath);
  if (!decoded.startsWith('/') || decoded.contains('\\')) {
    return null;
  }
  final segments = decoded.split('/').where((segment) => segment.isNotEmpty);
  if (segments.any((segment) => segment == '.' || segment == '..')) {
    return null;
  }
  final relative = segments.join('/');
  return relative.isEmpty ? 'index.html' : relative;
}

ContentType _contentTypeFor(String path) {
  if (path.endsWith('.html')) {
    return ContentType.html;
  }
  if (path.endsWith('.js')) {
    return ContentType('text', 'javascript', charset: 'utf-8');
  }
  if (path.endsWith('.json')) {
    return ContentType.json;
  }
  if (path.endsWith('.css')) {
    return ContentType('text', 'css', charset: 'utf-8');
  }
  if (path.endsWith('.wasm')) {
    return ContentType('application', 'wasm');
  }
  if (path.endsWith('.png')) {
    return ContentType('image', 'png');
  }
  if (path.endsWith('.svg')) {
    return ContentType('image', 'svg+xml');
  }
  if (path.endsWith('.woff2')) {
    return ContentType('font', 'woff2');
  }
  if (path.endsWith('.ttf')) {
    return ContentType('font', 'ttf');
  }
  return ContentType.binary;
}
