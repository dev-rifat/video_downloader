import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import 'extractors/video_extractor.dart';

typedef ProgressCallback = void Function(int received, int? total);

/// Streams media straight to disk (constant memory, no full-file buffering).
class FileDownloader {
  FileDownloader(this._dio);
  final Dio _dio;

  Future<void> download(
    MediaSource source,
    String path, {
    required ProgressCallback onProgress,
    required CancelToken cancelToken,
  }) async {
    switch (source) {
      case HttpMediaSource(:final url, :final headers):
        try {
          await _dio.download(
            url,
            path,
            cancelToken: cancelToken,
            deleteOnError: true,
            options: Options(
              headers: headers,
              receiveTimeout: const Duration(minutes: 2),
            ),
            onReceiveProgress: (r, t) => onProgress(r, t > 0 ? t : null),
          );
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) throw const DownloadCanceledException();
          rethrow;
        }
      case StreamMediaSource(:final stream, :final totalBytes):
        await _pipe(stream, totalBytes, path, onProgress, cancelToken);
    }
  }

  Future<void> _pipe(
    Stream<List<int>> stream,
    int? total,
    String path,
    ProgressCallback onProgress,
    CancelToken token,
  ) async {
    final sink = File(path).openWrite();
    final done = Completer<void>();
    var received = 0;

    final sub = stream.listen(
      (chunk) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      },
      onError: (Object e, StackTrace s) {
        if (!done.isCompleted) done.completeError(e, s);
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );
    unawaited(token.whenCancel.then((_) {
      sub.cancel();
      if (!done.isCompleted) {
        done.completeError(const DownloadCanceledException());
      }
    }));

    try {
      await done.future;
    } finally {
      await sink.flush();
      await sink.close();
    }
  }
}
