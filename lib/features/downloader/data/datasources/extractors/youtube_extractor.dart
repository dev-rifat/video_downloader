import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../domain/entities/video_format.dart';
import '../../../domain/entities/video_info.dart';
import '../../../domain/entities/video_platform.dart';
import 'video_extractor.dart';

/// On-device YouTube extraction. Muxed (audio+video) streams only,
/// so no FFmpeg is needed — keeps the APK small.
class YoutubeExtractor implements VideoExtractor {
  YoutubeExtractor() : _yt = YoutubeExplode();

  final YoutubeExplode _yt;

  /// Small bounded cache so resolving a format doesn't refetch the manifest.
  final _cache = <String, MuxedStreamInfo>{};
  static const _maxCache = 24;

  @override
  String get id => 'youtube';

  @override
  bool canHandle(Uri uri) => VideoId.parseVideoId(uri.toString()) != null;

  @override
  Future<VideoInfo> extract(Uri uri) async {
    final videoId = VideoId(uri.toString());
    final results = await Future.wait([
      _yt.videos.get(videoId),
      _manifest(videoId),
    ]);
    final video = results[0] as Video;
    final muxed = results[1] as List<MuxedStreamInfo>;
    if (muxed.isEmpty) {
      throw const ExtractionException('No downloadable stream for this video.');
    }

    final seen = <String>{};
    final formats = <VideoFormat>[];
    for (final s in muxed) {
      if (!seen.add(s.qualityLabel)) continue;
      final key = '${videoId.value}|${s.tag}';
      _remember(key, s);
      formats.add(VideoFormat(
        id: key,
        label: s.qualityLabel,
        height: s.videoResolution.height,
        sizeBytes: s.size.totalBytes,
        extension: s.container.name,
      ));
    }

    return VideoInfo(
      sourceUrl: uri.toString(),
      title: video.title,
      author: video.author,
      duration: video.duration,
      thumbnailUrl: video.thumbnails.highResUrl,
      platform: VideoPlatform.youtube,
      extractorId: id,
      formats: formats,
    );
  }

  @override
  Future<MediaSource> resolve(VideoInfo info, VideoFormat format) async {
    var stream = _cache[format.id];
    if (stream == null) {
      final parts = format.id.split('|');
      final list = await _manifest(VideoId(parts.first));
      stream = list.firstWhere(
        (s) => '${s.tag}' == parts.last,
        orElse: () => throw const ExtractionException('Stream expired.'),
      );
    }
    // The library downloads in throttling-safe chunks.
    return StreamMediaSource(
      _yt.videos.streams.get(stream),
      totalBytes: stream.size.totalBytes,
    );
  }

  Future<List<MuxedStreamInfo>> _manifest(VideoId id) async {
    var manifest = await _yt.videos.streams.getManifest(id);
    if (manifest.muxed.isEmpty) {
      manifest = await _yt.videos.streams.getManifest(
        id,
        ytClients: [YoutubeApiClient.safari, YoutubeApiClient.androidVr],
      );
    }
    return manifest.muxed.toList()
      ..sort((a, b) => b.videoResolution.height
          .compareTo(a.videoResolution.height));
  }

  void _remember(String key, MuxedStreamInfo s) {
    if (_cache.length >= _maxCache) _cache.remove(_cache.keys.first);
    _cache[key] = s;
  }
}
