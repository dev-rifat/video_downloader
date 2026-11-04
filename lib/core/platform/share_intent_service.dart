import 'dart:async';

import 'package:flutter/services.dart';

/// Receives text/links shared into the app (e.g. Facebook "Share > Downloader").
/// Implemented natively in MainActivity.kt — no third-party plugin needed.
class ShareIntentService {
  static const _method = MethodChannel('downloader/share');
  static const _events = EventChannel('downloader/share/events');

  Stream<String>? _stream;

  /// Text that launched the app (cold start), consumed once.
  Future<String?> initialText() async {
    try {
      return await _method.invokeMethod<String>('getInitialText');
    } on MissingPluginException {
      return null; // Platform without native support (e.g. iOS/web).
    } on PlatformException {
      return null;
    }
  }

  /// Text shared while the app is already running (warm start).
  Stream<String> get textStream => _stream ??= _events
      .receiveBroadcastStream()
      .where((e) => e is String && e.isNotEmpty)
      .cast<String>()
      .handleError((_) {});
}
