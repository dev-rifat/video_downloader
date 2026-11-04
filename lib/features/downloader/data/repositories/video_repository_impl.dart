import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    show YoutubeExplodeException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/result.dart';
import '../../domain/entities/video_info.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/extractors/video_extractor.dart';

class VideoRepositoryImpl implements VideoRepository {
  /// [extractors] in priority order; the first that succeeds wins.
  VideoRepositoryImpl(this._extractors);
  final List<VideoExtractor> _extractors;

  // Small LRU: sharing/pasting the same link twice is instant.
  final _cache = <String, VideoInfo>{};

  VideoExtractor extractorFor(String id) =>
      _extractors.firstWhere((e) => e.id == id);

  @override
  Future<Result<VideoInfo>> analyze(String url) async {
    final cached = _cache.remove(url);
    if (cached != null) return Success(_cache[url] = cached);

    final uri = Uri.parse(url);
    Failure? firstFailure;
    for (final ex in _extractors.where((e) => e.canHandle(uri))) {
      try {
        final info = await ex.extract(uri);
        if (info.formats.isEmpty) continue;
        if (_cache.length >= 10) _cache.remove(_cache.keys.first);
        return Success(_cache[url] = info);
      } catch (e) {
        firstFailure ??= _map(e);
        // Network failures won't be fixed by another extractor.
        if (firstFailure is NetworkFailure) break;
      }
    }
    return Error(firstFailure ?? const ExtractionFailure());
  }

  static Failure _map(Object e) => switch (e) {
        ExtractionException(:final message) => ExtractionFailure(message),
        DioException(type: DioExceptionType.connectionError) ||
        DioException(type: DioExceptionType.connectionTimeout) ||
        DioException(type: DioExceptionType.receiveTimeout) =>
          const NetworkFailure(),
        DioException(:final response?) when response.statusCode == 404 =>
          const ExtractionFailure('Video not found (404).'),
        YoutubeExplodeException() =>
          const ExtractionFailure('YouTube video is unavailable or private.'),
        _ => const ExtractionFailure(),
      };
}
