import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'browser_recovery_archive.dart';

typedef BrowserDownloadTrigger =
    Future<void> Function(Uint8List bytes, String suggestedName);
typedef BrowserFileSelector = Future<web.File?> Function();
typedef BrowserClipboardWriter = Future<void> Function(String value);

/// One user-selected browser file copied into bounded Dart-owned memory.
final class BrowserSelectedRecoveryArchive {
  BrowserSelectedRecoveryArchive({required this.name, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes);

  final String name;
  final Uint8List bytes;
}

/// Browser download, file-picker, and sensitive clipboard boundary for RBP1.
final class BrowserRecoveryDocumentPortal {
  BrowserRecoveryDocumentPortal({
    BrowserDownloadTrigger? downloadTrigger,
    BrowserFileSelector? fileSelector,
    BrowserClipboardWriter? clipboardWriter,
  }) : _downloadTrigger = downloadTrigger ?? _download,
       _fileSelector = fileSelector ?? _selectFile,
       _clipboardWriter = clipboardWriter ?? _copyToClipboard;

  static final RegExp _safeSuggestedName = RegExp(
    r'^[A-Za-z0-9._-]{1,96}\.reboot-backup$',
  );
  static final RegExp _recoveryCode = RegExp(
    r'^RBP1\.[A-Za-z0-9_-]{6}(?:\.[A-Za-z0-9_-]{6}){6}'
    r'\.[A-Za-z0-9_-]$',
  );

  final BrowserDownloadTrigger _downloadTrigger;
  final BrowserFileSelector _fileSelector;
  final BrowserClipboardWriter _clipboardWriter;
  bool _busy = false;

  /// Starts a same-origin Blob download from a direct user action.
  Future<void> save({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    _requireIdle();
    if (!_safeSuggestedName.hasMatch(suggestedName)) {
      throw const BrowserRecoveryDocumentException(
        BrowserRecoveryDocumentFailureReason.invalidName,
      );
    }
    _requireBoundedBytes(bytes);
    _busy = true;
    try {
      await _downloadTrigger(Uint8List.fromList(bytes), suggestedName);
    } on BrowserRecoveryDocumentException {
      rethrow;
    } on Object {
      throw const BrowserRecoveryDocumentException(
        BrowserRecoveryDocumentFailureReason.unavailable,
      );
    } finally {
      _busy = false;
    }
  }

  /// Lets the user select one local file and copies it into bounded memory.
  Future<BrowserSelectedRecoveryArchive?> pick() async {
    _requireIdle();
    _busy = true;
    try {
      final file = await _fileSelector();
      if (file == null) return null;
      if (file.size <= 0) {
        throw const BrowserRecoveryDocumentException(
          BrowserRecoveryDocumentFailureReason.invalidFile,
        );
      }
      if (file.size > browserRecoveryMaximumArchiveBytes) {
        throw const BrowserRecoveryDocumentException(
          BrowserRecoveryDocumentFailureReason.tooLarge,
        );
      }
      final buffer = await file.arrayBuffer().toDart;
      final bytes = Uint8List.fromList(Uint8List.view(buffer.toDart));
      _requireBoundedBytes(bytes);
      return BrowserSelectedRecoveryArchive(name: file.name, bytes: bytes);
    } on BrowserRecoveryDocumentException {
      rethrow;
    } on Object {
      throw const BrowserRecoveryDocumentException(
        BrowserRecoveryDocumentFailureReason.unavailable,
      );
    } finally {
      _busy = false;
    }
  }

  /// Copies a syntactically valid recovery code through the secure-context API.
  Future<void> copySensitive(String recoveryCode) async {
    _requireIdle();
    final compact = recoveryCode.replaceAll(RegExp(r'\s'), '');
    if (!_recoveryCode.hasMatch(compact)) {
      throw const BrowserRecoveryDocumentException(
        BrowserRecoveryDocumentFailureReason.invalidRecoveryCode,
      );
    }
    _busy = true;
    try {
      await _clipboardWriter(compact);
    } on BrowserRecoveryDocumentException {
      rethrow;
    } on Object {
      throw const BrowserRecoveryDocumentException(
        BrowserRecoveryDocumentFailureReason.clipboardUnavailable,
      );
    } finally {
      _busy = false;
    }
  }

  void _requireIdle() {
    if (_busy) {
      throw const BrowserRecoveryDocumentException(
        BrowserRecoveryDocumentFailureReason.busy,
      );
    }
  }
}

enum BrowserRecoveryDocumentFailureReason {
  busy,
  invalidName,
  invalidFile,
  invalidRecoveryCode,
  tooLarge,
  clipboardUnavailable,
  unavailable,
}

final class BrowserRecoveryDocumentException implements Exception {
  const BrowserRecoveryDocumentException(this.reason);

  final BrowserRecoveryDocumentFailureReason reason;
}

void _requireBoundedBytes(Uint8List bytes) {
  if (bytes.isEmpty) {
    throw const BrowserRecoveryDocumentException(
      BrowserRecoveryDocumentFailureReason.invalidFile,
    );
  }
  if (bytes.length > browserRecoveryMaximumArchiveBytes) {
    throw const BrowserRecoveryDocumentException(
      BrowserRecoveryDocumentFailureReason.tooLarge,
    );
  }
}

Future<void> _download(Uint8List bytes, String suggestedName) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = suggestedName
    ..rel = 'noopener'
    ..style.display = 'none';
  final body = web.document.body;
  if (body == null) {
    web.URL.revokeObjectURL(objectUrl);
    throw const BrowserRecoveryDocumentException(
      BrowserRecoveryDocumentFailureReason.unavailable,
    );
  }
  body.append(anchor);
  try {
    anchor.click();
    await Future<void>.delayed(Duration.zero);
  } finally {
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);
  }
}

Future<web.File?> _selectFile() {
  final body = web.document.body;
  if (body == null) {
    throw const BrowserRecoveryDocumentException(
      BrowserRecoveryDocumentFailureReason.unavailable,
    );
  }
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.reboot-backup,application/octet-stream,application/json'
    ..multiple = false
    ..style.display = 'none';
  final completer = Completer<web.File?>();

  void complete(web.File? file) {
    if (!completer.isCompleted) completer.complete(file);
  }

  input.onchange = ((web.Event _) {
    final files = input.files;
    complete(files == null || files.length == 0 ? null : files.item(0));
  }).toJS;
  input.oncancel = ((web.Event _) => complete(null)).toJS;
  body.append(input);
  try {
    input.click();
  } on Object {
    input.remove();
    throw const BrowserRecoveryDocumentException(
      BrowserRecoveryDocumentFailureReason.unavailable,
    );
  }
  return completer.future.whenComplete(() => input.remove());
}

Future<void> _copyToClipboard(String value) async {
  await web.window.navigator.clipboard.writeText(value).toDart;
}
