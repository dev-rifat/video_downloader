import '../../features/downloader/domain/entities/video_platform.dart';

abstract final class LinkUtils {
  static final _urlRegex = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

  /// Pulls the first URL out of arbitrary shared text
  /// (Facebook/Instagram share text often contains extra words).
  static String? extractUrl(String? text) {
    if (text == null) return null;
    final match = _urlRegex.firstMatch(text.trim());
    if (match != null) return match.group(0);
    // Allow "www.facebook.com/..." without scheme.
    final t = text.trim();
    if (RegExp(r'^[\w-]+(\.[\w-]+)+/\S*$').hasMatch(t)) return 'https://$t';
    return null;
  }

  static VideoPlatform detectPlatform(Uri uri) {
    final h = uri.host.toLowerCase();
    bool has(String d) => h == d || h.endsWith('.$d');
    if (has('youtube.com') || has('youtu.be')) return VideoPlatform.youtube;
    if (has('facebook.com') || has('fb.watch') || has('fb.com')) {
      return VideoPlatform.facebook;
    }
    if (has('instagram.com')) return VideoPlatform.instagram;
    if (has('tiktok.com')) return VideoPlatform.tiktok;
    if (has('twitter.com') || has('x.com')) return VideoPlatform.twitter;
    return VideoPlatform.other;
  }
}
