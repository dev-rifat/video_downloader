import 'package:dio/dio.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/utils/link_utils.dart';
import '../../../domain/entities/video_format.dart';
import '../../../domain/entities/video_info.dart';
import 'html_utils.dart';
import 'video_extractor.dart';

/// Last-resort extractor: direct media links and pages exposing
/// `og:video` / `<video src>` (many news, blog and smaller social sites).
class GenericExtractor implements VideoExtractor {
  GenericExtractor(this._dio);
  final Dio _dio;

  static final _directExt =
      RegExp(r'\.(mp4|m4v|mov|webm|mkv|3gp)$', caseSensitive: false);

  @override
  String get id => 'generic';

  @override
  bool canHandle(Uri uri) => true;

  @override
  Future<VideoInfo> extract(Uri uri) async {
    final platform = LinkUtils.detectPlatform(uri);
    final direct = _directExt.firstMatch(uri.path);
    if (direct != null) {
      final name = Uri.decodeComponent(uri.pathSegments.last);
      return VideoInfo(
        sourceUrl: uri.toString(),
        title: name.replaceAll(_directExt, ''),
        platform: platform,
        extractorId: id,
        formats: [
          VideoFormat(
            id: uri.toString(),
            label: 'Original',
            extension: direct.group(1)!.toLowerCase(),
          ),
        ],
      );
    }

    final res = await _dio.get<String>(
      uri.toString(),
      options: Options(responseType: ResponseType.plain),
    );
    final html = res.data ?? '';
    final candidates = <String?>[
      HtmlUtils.meta(html, 'og:video:secure_url'),
      HtmlUtils.meta(html, 'og:video:url'),
      HtmlUtils.meta(html, 'og:video'),
      HtmlUtils.meta(html, 'twitter:player:stream'),
      RegExp(r'<video[^>]+src="([^"]+)"', caseSensitive: false)
          .firstMatch(html)
          ?.group(1),
      RegExp(r'<source[^>]+src="([^"]+\.mp4[^"]*)"', caseSensitive: false)
          .firstMatch(html)
          ?.group(1),
    ];
    final found = candidates.whereType<String>().map((u) {
      return uri.resolve(HtmlUtils.decodeEntities(u)).toString();
    }).firstWhere(
      (u) => !u.contains('.m3u8') && !u.contains('/embed'),
      orElse: () => '',
    );
    if (found.isEmpty) {
      throw const ExtractionException(
          'No video found. Add a universal server in Settings for this site.');
    }

    return VideoInfo(
      sourceUrl: uri.toString(),
      title: HtmlUtils.meta(html, 'og:title') ??
          HtmlUtils.title(html) ??
          'Video',
      thumbnailUrl: HtmlUtils.meta(html, 'og:image'),
      platform: platform,
      extractorId: id,
      formats: [VideoFormat(id: found, label: 'Original')],
    );
  }

  @override
  Future<MediaSource> resolve(VideoInfo info, VideoFormat format) async =>
      HttpMediaSource(format.id, headers: {'Referer': info.sourceUrl});
}
