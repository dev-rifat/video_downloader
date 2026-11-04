import '../../../domain/entities/video_format.dart';
import '../../../domain/entities/video_info.dart';

/// Where the bytes of a chosen format come from.
sealed class MediaSource {
  const MediaSource();
}

final class HttpMediaSource extends MediaSource {
  const HttpMediaSource(this.url, {this.headers = const {}});
  final String url;
  final Map<String, String> headers;
}

final class StreamMediaSource extends MediaSource {
  const StreamMediaSource(this.stream, {this.totalBytes});
  final Stream<List<int>> stream;
  final int? totalBytes;
}

/// Strategy interface: one implementation per platform/backend.
/// Throws [ExtractionException] / [DioException] on failure.
abstract interface class VideoExtractor {
  String get id;
  bool canHandle(Uri uri);
  Future<VideoInfo> extract(Uri uri);
  Future<MediaSource> resolve(VideoInfo info, VideoFormat format);
}
