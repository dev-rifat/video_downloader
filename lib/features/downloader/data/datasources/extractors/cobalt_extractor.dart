import 'package:dio/dio.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/utils/link_utils.dart';
import '../../../../settings/domain/server_settings.dart';
import '../../../domain/entities/video_format.dart';
import '../../../domain/entities/video_info.dart';
import '../../../domain/entities/video_platform.dart';
import 'html_utils.dart';
import 'video_extractor.dart';

/// Universal extractor backed by a cobalt-compatible API
/// (supports Instagram, TikTok, X, Reddit, Vimeo, YouTube HD, Facebook…).
/// Only active when the user configured a server in Settings.
class CobaltExtractor implements VideoExtractor {
  CobaltExtractor(this._dio, this._settings);
  final Dio _dio;
  final SettingsRepository _settings;

  static const _qualities = [2160, 1440, 1080, 720, 480, 360, 240];

  @override
  String get id => 'cobalt';

  @override
  bool canHandle(Uri uri) => _settings.current.isConfigured;

  @override
  Future<VideoInfo> extract(Uri uri) async {
    final platform = LinkUtils.detectPlatform(uri);
    // Validate the link with a cheap request at a mid quality, and fetch
    // page metadata (title/thumbnail) in parallel.
    final results = await Future.wait([
      _request(uri.toString(), 720),
      _pageMeta(uri),
    ]);
    final meta = results[1] as ({String? title, String? thumb});

    // Some platforms (TikTok/Instagram/X) only ship one quality.
    final multi = platform == VideoPlatform.youtube ||
        platform == VideoPlatform.facebook ||
        platform == VideoPlatform.other;
    final formats = multi
        ? _qualities
            .map((q) => VideoFormat(id: '$q', label: '${q}p', height: q))
            .toList()
        : const [VideoFormat(id: 'max', label: 'Best')];

    return VideoInfo(
      sourceUrl: uri.toString(),
      title: meta.title ?? '${platform.label} video',
      thumbnailUrl: meta.thumb,
      platform: platform,
      extractorId: id,
      formats: formats,
    );
  }

  @override
  Future<MediaSource> resolve(VideoInfo info, VideoFormat format) async {
    final q = int.tryParse(format.id);
    final url = await _request(info.sourceUrl, q);
    return HttpMediaSource(url);
  }

  Future<String> _request(String url, int? quality) async {
    final s = _settings.current;
    final res = await _dio.post<Map<String, dynamic>>(
      '${s.endpoint}/',
      data: {
        'url': url,
        'videoQuality': quality == null ? 'max' : '$quality',
        'downloadMode': 'auto',
        'filenameStyle': 'basic',
      },
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (s.apiKey.isNotEmpty) 'Authorization': 'Api-Key ${s.apiKey}',
        },
        validateStatus: (_) => true,
      ),
    );
    final body = res.data ?? const {};
    switch (body['status']) {
      case 'tunnel' || 'redirect' || 'stream':
        return body['url'] as String;
      case 'picker':
        final items = (body['picker'] as List?) ?? const [];
        final video = items.cast<Map>().firstWhere(
              (e) => e['type'] == 'video',
              orElse: () => items.isEmpty ? const {} : items.first as Map,
            );
        final u = video['url'];
        if (u is String) return u;
        throw const ExtractionException('No video found in this post.');
      default:
        final err = body['error'];
        final code = err is Map ? err['code'] : body['text'];
        throw ExtractionException('Server: ${code ?? 'unsupported link'}');
    }
  }

  Future<({String? title, String? thumb})> _pageMeta(Uri uri) async {
    try {
      final res = await _dio.get<String>(
        uri.toString(),
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final html = res.data ?? '';
      return (
        title: HtmlUtils.meta(html, 'og:title') ?? HtmlUtils.title(html),
        thumb: HtmlUtils.meta(html, 'og:image'),
      );
    } catch (_) {
      return (title: null, thumb: null);
    }
  }
}
