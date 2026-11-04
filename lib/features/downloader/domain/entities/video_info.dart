import 'package:equatable/equatable.dart';

import 'video_format.dart';
import 'video_platform.dart';

class VideoInfo extends Equatable {
  const VideoInfo({
    required this.sourceUrl,
    required this.title,
    required this.platform,
    required this.extractorId,
    required this.formats,
    this.thumbnailUrl,
    this.author,
    this.duration,
  });

  final String sourceUrl;
  final String title;
  final VideoPlatform platform;

  /// Which extractor resolved this; used again when downloading.
  final String extractorId;
  final List<VideoFormat> formats; // sorted best → worst
  final String? thumbnailUrl;
  final String? author;
  final Duration? duration;

  @override
  List<Object?> get props =>
      [sourceUrl, title, platform, extractorId, formats, thumbnailUrl];
}
