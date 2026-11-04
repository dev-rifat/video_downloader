import 'package:dio/dio.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/utils/link_utils.dart';
import '../../../domain/entities/video_format.dart';
import '../../../domain/entities/video_info.dart';
import '../../../domain/entities/video_platform.dart';
import 'html_utils.dart';
import 'video_extractor.dart';

/// Scrapes public Facebook video/reel pages for HD/SD progressive MP4s.
/// Works for public posts; private/login-only videos fall through to
/// the universal server extractor.
class FacebookExtractor implements VideoExtractor {
  FacebookExtractor(this._dio);
  final Dio _dio;

  @override
  String get id => 'facebook';

  @override
  bool canHandle(Uri uri) =>
      LinkUtils.detectPlatform(uri) == VideoPlatform.facebook;

  static final _patterns = <String, List<RegExp>>{
    'HD': [
      RegExp(r'"browser_native_hd_url":"([^"]+)"'),
      RegExp(r'"playable_url_quality_hd":"([^"]+)"'),
      RegExp(r'hd_src(?:_no_ratelimit)?:"([^"]+)"'),
    ],
    'SD': [
      RegExp(r'"browser_native_sd_url":"([^"]+)"'),
      RegExp(r'"playable_url":"([^"]+)"'),
      RegExp(r'sd_src(?:_no_ratelimit)?:"([^"]+)"'),
    ],
  };

  @override
  Future<VideoInfo> extract(Uri uri) async {
    final res = await _dio.get<String>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'Accept': 'text/html,application/xhtml+xml',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Dest': 'document',
        },
      ),
    );
    final html = res.data ?? '';

    final formats = <VideoFormat>[];
    final urls = <String>{};
    _patterns.forEach((label, regs) {
      for (final r in regs) {
        final m = r.firstMatch(html);
        if (m == null) continue;
        final url = HtmlUtils.unescapeJson(m.group(1)!);
        if (url.startsWith('http') && urls.add(url)) {
          formats.add(VideoFormat(
            id: url,
            label: label,
            height: label == 'HD' ? 720 : 360,
          ));
        }
        break;
      }
    });

    if (formats.isEmpty) {
      throw const ExtractionException(
          'Video is private or needs login. Try the universal server.');
    }

    final thumbMatch =
        RegExp(r'"preferred_thumbnail":\{"image":\{"uri":"([^"]+)"')
            .firstMatch(html);
    return VideoInfo(
      sourceUrl: uri.toString(),
      title: HtmlUtils.meta(html, 'og:title') ??
          HtmlUtils.title(html) ??
          'Facebook video',
      thumbnailUrl: HtmlUtils.meta(html, 'og:image') ??
          (thumbMatch == null
              ? null
              : HtmlUtils.unescapeJson(thumbMatch.group(1)!)),
      platform: VideoPlatform.facebook,
      extractorId: id,
      formats: formats,
    );
  }

  @override
  Future<MediaSource> resolve(VideoInfo info, VideoFormat format) async =>
      HttpMediaSource(format.id, headers: const {'Referer': 'https://www.facebook.com/'});
}
