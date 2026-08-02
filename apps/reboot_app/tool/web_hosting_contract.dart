final class WebHostingContract {
  WebHostingContract._(this._routes);

  factory WebHostingContract.parse(String source) {
    final routes = <String, Map<String, String>>{};
    String? currentRoute;

    for (final rawLine in source.split(RegExp(r'\r?\n'))) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (rawLine.startsWith(' ') || rawLine.startsWith('\t')) {
        if (currentRoute == null) {
          throw const FormatException('Header declared before any route.');
        }
        final separator = trimmed.indexOf(':');
        if (separator <= 0) {
          throw FormatException('Malformed header: $trimmed');
        }
        final name = trimmed.substring(0, separator).trim().toLowerCase();
        final value = trimmed.substring(separator + 1).trim();
        if (value.isEmpty) {
          throw FormatException('Empty value for header $name.');
        }
        if (routes[currentRoute]!.containsKey(name)) {
          throw FormatException(
            'Duplicate header $name for route $currentRoute.',
          );
        }
        routes[currentRoute]![name] = value;
        continue;
      }

      if (!trimmed.startsWith('/')) {
        throw FormatException('Malformed route: $trimmed');
      }
      if (routes.containsKey(trimmed)) {
        throw FormatException('Duplicate route: $trimmed');
      }
      currentRoute = trimmed;
      routes[currentRoute] = <String, String>{};
    }

    return WebHostingContract._(routes);
  }

  final Map<String, Map<String, String>> _routes;

  Map<String, String> headersFor(String path) {
    final headers = <String, String>{...?_routes['/*']};
    headers.addAll(_routes[path] ?? const <String, String>{});
    return Map.unmodifiable(headers);
  }

  void validate() {
    final global = _requiredRoute('/*');
    _requireExact(global, 'cross-origin-opener-policy', 'same-origin');
    _requireExact(global, 'cross-origin-embedder-policy', 'require-corp');
    _requireExact(global, 'cross-origin-resource-policy', 'same-origin');
    _requireExact(global, 'referrer-policy', 'no-referrer');
    _requireExact(global, 'x-content-type-options', 'nosniff');
    _requireExact(global, 'x-frame-options', 'DENY');
    _requireExact(
      global,
      'strict-transport-security',
      'max-age=31536000; includeSubDomains',
    );

    final permissions = _requiredHeader(global, 'permissions-policy');
    for (final deniedCapability in const [
      'camera=()',
      'microphone=()',
      'geolocation=()',
      'payment=()',
      'usb=()',
      'browsing-topics=()',
    ]) {
      if (!permissions
          .split(',')
          .map((part) => part.trim())
          .contains(deniedCapability)) {
        throw FormatException(
          'Permissions-Policy must deny $deniedCapability.',
        );
      }
    }

    final csp = _requiredHeader(global, 'content-security-policy');
    if (csp.length > 2000) {
      throw const FormatException(
        'Content-Security-Policy exceeds the hosting line limit.',
      );
    }
    _validateContentSecurityPolicy(csp);

    _requireExact(
      _requiredRoute('/'),
      'cache-control',
      'no-cache, no-store, must-revalidate',
    );
    _requireExact(
      _requiredRoute('/index.html'),
      'cache-control',
      'no-cache, no-store, must-revalidate',
    );
    _requireExact(
      _requiredRoute('/flutter_bootstrap.js'),
      'cache-control',
      'no-cache, must-revalidate',
    );
    _requireExact(
      _requiredRoute('/reboot_service_worker.js'),
      'cache-control',
      'no-cache, no-store, must-revalidate',
    );
    _requireExact(
      _requiredRoute('/manifest.json'),
      'cache-control',
      'no-cache, must-revalidate',
    );
  }

  Map<String, String> _requiredRoute(String route) {
    final headers = _routes[route];
    if (headers == null) {
      throw FormatException('Missing hosting rule for $route.');
    }
    return headers;
  }
}

void _validateContentSecurityPolicy(String source) {
  final directives = <String, List<String>>{};
  for (final rawDirective in source.split(';')) {
    final parts = rawDirective.trim().split(RegExp(r'\s+'));
    if (parts.length == 1 && parts.single.isEmpty) {
      continue;
    }
    final name = parts.first.toLowerCase();
    if (directives.containsKey(name)) {
      throw FormatException('Duplicate CSP directive $name.');
    }
    directives[name] = parts.skip(1).toList(growable: false);
  }

  const expected = <String, List<String>>{
    'default-src': ["'self'"],
    'base-uri': ["'self'"],
    'object-src': ["'none'"],
    'frame-ancestors': ["'none'"],
    'form-action': ["'none'"],
    'script-src': ["'self'", "'wasm-unsafe-eval'"],
    'worker-src': ["'self'", 'blob:'],
    'connect-src': ["'self'"],
    'img-src': ["'self'", 'data:', 'blob:'],
    'font-src': ["'self'", 'data:'],
    'style-src': ["'self'", "'unsafe-inline'"],
    'manifest-src': ["'self'"],
    'media-src': ["'none'"],
    'frame-src': ["'none'"],
    'upgrade-insecure-requests': [],
  };

  for (final entry in expected.entries) {
    final actual = directives[entry.key];
    if (actual == null || !_sameValues(actual, entry.value)) {
      throw FormatException(
        'Unexpected or missing CSP directive ${entry.key}.',
      );
    }
  }

  final scriptSources = directives['script-src']!;
  if (scriptSources.contains("'unsafe-inline'") ||
      scriptSources.contains("'unsafe-eval'")) {
    throw const FormatException(
      'script-src must not allow unsafe-inline or unsafe-eval.',
    );
  }
}

bool _sameValues(List<String> actual, List<String> expected) {
  return actual.length == expected.length &&
      actual.toSet().containsAll(expected) &&
      expected.toSet().containsAll(actual);
}

String _requiredHeader(Map<String, String> headers, String name) {
  final value = headers[name];
  if (value == null) {
    throw FormatException('Missing required header $name.');
  }
  return value;
}

void _requireExact(Map<String, String> headers, String name, String expected) {
  final actual = _requiredHeader(headers, name);
  if (actual != expected) {
    throw FormatException('Unexpected value for $name: $actual');
  }
}
