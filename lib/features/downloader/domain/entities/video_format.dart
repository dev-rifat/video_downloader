import 'package:equatable/equatable.dart';

/// One selectable resolution/quality of a video.
class VideoFormat extends Equatable {
  const VideoFormat({
    required this.id,
    required this.label,
    this.height,
    this.sizeBytes,
    this.extension = 'mp4',
  });

  /// Opaque id understood by the extractor that produced it.
  final String id;
  final String label; // e.g. "720p", "HD", "SD"
  final int? height;
  final int? sizeBytes;
  final String extension;

  @override
  List<Object?> get props => [id, label, height, sizeBytes, extension];
}
