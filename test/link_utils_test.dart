import 'package:downloader/core/utils/link_utils.dart';
import 'package:downloader/features/downloader/domain/entities/video_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts URL from Facebook share text', () {
    expect(
      LinkUtils.extractUrl('Check this out! https://fb.watch/abc123/ 🔥'),
      'https://fb.watch/abc123/',
    );
    expect(LinkUtils.extractUrl('www.facebook.com/reel/123'),
        'https://www.facebook.com/reel/123');
    expect(LinkUtils.extractUrl('no link here'), isNull);
  });

  test('detects platforms', () {
    VideoPlatform p(String u) => LinkUtils.detectPlatform(Uri.parse(u));
    expect(p('https://m.facebook.com/watch?v=1'), VideoPlatform.facebook);
    expect(p('https://fb.watch/x'), VideoPlatform.facebook);
    expect(p('https://youtu.be/dQw4w9WgXcQ'), VideoPlatform.youtube);
    expect(p('https://www.instagram.com/reel/x'), VideoPlatform.instagram);
    expect(p('https://vm.tiktok.com/x'), VideoPlatform.tiktok);
    expect(p('https://x.com/a/status/1'), VideoPlatform.twitter);
    expect(p('https://example.com/v.mp4'), VideoPlatform.other);
  });
}
