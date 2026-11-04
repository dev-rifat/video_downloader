import 'package:equatable/equatable.dart';

import 'video_platform.dart';

enum DownloadStatus { queued, downloading, saving, completed, failed, canceled }

extension DownloadStatusX on DownloadStatus {
  bool get isActive =>
      this == DownloadStatus.queued ||
      this == DownloadStatus.downloading ||
      this == DownloadStatus.saving;
}

class DownloadTask extends Equatable {
  const DownloadTask({
    required this.id,
    required this.title,
    required this.platform,
    required this.qualityLabel,
    required this.status,
    required this.createdAt,
    this.thumbnailUrl,
    this.received = 0,
    this.total,
    this.bytesPerSecond = 0,
    this.error,
  });

  final String id;
  final String title;
  final VideoPlatform platform;
  final String qualityLabel;
  final DownloadStatus status;
  final DateTime createdAt;
  final String? thumbnailUrl;
  final int received;
  final int? total;
  final int bytesPerSecond;
  final String? error;

  /// 0..1, or null when the server didn't send a size.
  double? get progress =>
      (total == null || total == 0) ? null : (received / total!).clamp(0, 1);

  DownloadTask copyWith({
    DownloadStatus? status,
    int? received,
    int? total,
    int? bytesPerSecond,
    String? error,
  }) =>
      DownloadTask(
        id: id,
        title: title,
        platform: platform,
        qualityLabel: qualityLabel,
        createdAt: createdAt,
        thumbnailUrl: thumbnailUrl,
        status: status ?? this.status,
        received: received ?? this.received,
        total: total ?? this.total,
        bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [id, status, received, total, bytesPerSecond, error];
}
