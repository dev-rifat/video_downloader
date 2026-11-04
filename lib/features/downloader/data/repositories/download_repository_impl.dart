import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/video_format.dart';
import '../../domain/entities/video_info.dart';
import '../../domain/repositories/download_repository.dart';
import '../datasources/download_history_local_data_source.dart';
import '../datasources/file_downloader.dart';
import '../datasources/gallery_data_source.dart';
import 'video_repository_impl.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl({
    required VideoRepositoryImpl videos,
    required FileDownloader downloader,
    required GalleryDataSource gallery,
    required DownloadHistoryLocalDataSource local,
  })  : _videos = videos,
        _downloader = downloader,
        _gallery = gallery,
        _local = local;

  final VideoRepositoryImpl _videos;
  final FileDownloader _downloader;
  final GalleryDataSource _gallery;
  final DownloadHistoryLocalDataSource _local;

  static const _maxConcurrent = 2;
  static const _progressInterval = Duration(milliseconds: 300);

  final _controller = StreamController<DownloadTask>.broadcast();
  final _tasks = <String, DownloadTask>{}; // newest first after load
  final _tokens = <String, CancelToken>{};
  final _queue = Queue<_Job>();
  var _running = 0;
  var _loaded = false;

  @override
  Stream<DownloadTask> get updates => _controller.stream;

  @override
  Future<List<DownloadTask>> history() async {
    if (!_loaded) {
      _loaded = true;
      for (final t in _local.load()) {
        // Anything that was mid-flight when the app died is interrupted.
        _tasks[t.id] = t.status.isActive
            ? t.copyWith(status: DownloadStatus.failed, error: 'Interrupted')
            : t;
      }
    }
    return _sorted();
  }

  @override
  DownloadTask start(VideoInfo info, VideoFormat format) {
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: info.title,
      platform: info.platform,
      qualityLabel: format.label,
      thumbnailUrl: info.thumbnailUrl,
      total: format.sizeBytes,
      status: DownloadStatus.queued,
      createdAt: DateTime.now(),
    );
    _emit(task);
    _queue.add(_Job(task.id, info, format));
    _pump();
    return task;
  }

  @override
  Future<void> cancel(String taskId) async {
    final queued = _queue.where((j) => j.taskId == taskId).toList();
    if (queued.isNotEmpty) {
      _queue.removeWhere((j) => j.taskId == taskId);
      _update(taskId, (t) => t.copyWith(status: DownloadStatus.canceled));
      await _persist();
      return;
    }
    _tokens[taskId]?.cancel();
  }

  @override
  Future<void> remove(String taskId) async {
    // Remove first so the cancel below doesn't re-emit this task.
    _tasks.remove(taskId);
    _queue.removeWhere((j) => j.taskId == taskId);
    _tokens[taskId]?.cancel();
    await _persist();
  }

  @override
  Future<void> openGallery() => _gallery.open();

  // ---------------------------------------------------------------------------

  void _pump() {
    while (_running < _maxConcurrent && _queue.isNotEmpty) {
      _running++;
      unawaited(_run(_queue.removeFirst()).whenComplete(() {
        _running--;
        _pump();
      }));
    }
  }

  Future<void> _run(_Job job) async {
    final id = job.taskId;
    final token = _tokens[id] = CancelToken();
    String? path;
    try {
      _update(id, (t) => t.copyWith(status: DownloadStatus.downloading));

      final source = await _videos
          .extractorFor(job.info.extractorId)
          .resolve(job.info, job.format);
      if (token.isCancelled) throw const DownloadCanceledException();

      final dir = await getTemporaryDirectory();
      final name = Formatters.safeFileName(job.info.title);
      path = '${dir.path}/${name}_${job.format.label}_$id.${job.format.extension}';

      // Throttled progress: at most ~3 UI updates/sec per task.
      var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
      var lastBytes = 0;
      await _downloader.download(
        source,
        path,
        cancelToken: token,
        onProgress: (received, total) {
          final now = DateTime.now();
          final elapsed = now.difference(lastEmit);
          if (elapsed < _progressInterval && received != total) return;
          final speed = elapsed.inMilliseconds > 0 && lastBytes > 0
              ? ((received - lastBytes) * 1000 ~/ elapsed.inMilliseconds)
              : 0;
          lastEmit = now;
          lastBytes = received;
          _update(id, (t) => t.copyWith(
                received: received,
                total: total ?? t.total,
                bytesPerSecond: speed,
              ));
        },
      );

      _update(id, (t) => t.copyWith(status: DownloadStatus.saving));
      if (!await _gallery.ensureAccess()) {
        throw const _UserError('Gallery permission denied.');
      }
      await _gallery.saveVideo(path);

      _update(id, (t) => t.copyWith(
            status: DownloadStatus.completed,
            received: t.total ?? t.received,
            bytesPerSecond: 0,
          ));
    } on DownloadCanceledException {
      _update(id, (t) => t.copyWith(status: DownloadStatus.canceled));
    } catch (e) {
      _update(id, (t) => t.copyWith(
            status: DownloadStatus.failed,
            bytesPerSecond: 0,
            error: _message(e),
          ));
    } finally {
      _tokens.remove(id);
      // Gallery holds its own copy — free app storage immediately.
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) unawaited(f.delete().catchError((_) => f));
      }
      await _persist();
    }
  }

  String _message(Object e) => switch (e) {
        _UserError(:final message) => message,
        ExtractionException(:final message) => message,
        GalException(type: GalExceptionType.accessDenied) =>
          'Gallery permission denied.',
        GalException(type: GalExceptionType.notEnoughSpace) =>
          'Not enough storage space.',
        GalException(type: GalExceptionType.notSupportedFormat) =>
          'Format not supported by gallery.',
        DioException(:final response?) =>
          'Server error (${response.statusCode}).',
        DioException() => 'Network error.',
        FileSystemException() => 'Storage error.',
        _ => 'Download failed.',
      };

  void _update(String id, DownloadTask Function(DownloadTask) f) {
    final t = _tasks[id];
    if (t != null) _emit(f(t));
  }

  void _emit(DownloadTask t) {
    _tasks[t.id] = t;
    _controller.add(t);
  }

  List<DownloadTask> _sorted() =>
      _tasks.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _persist() => _local.save(_sorted());
}

class _Job {
  const _Job(this.taskId, this.info, this.format);
  final String taskId;
  final VideoInfo info;
  final VideoFormat format;
}

class _UserError implements Exception {
  const _UserError(this.message);
  final String message;
}
