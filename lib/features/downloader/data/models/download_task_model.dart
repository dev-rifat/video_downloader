import '../../domain/entities/download_task.dart';
import '../../domain/entities/video_platform.dart';

/// JSON mapping kept out of the domain entity.
extension DownloadTaskModel on DownloadTask {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'platform': platform.name,
        'quality': qualityLabel,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'thumb': thumbnailUrl,
        'received': received,
        'total': total,
        'error': error,
      };

  static DownloadTask fromJson(Map<String, dynamic> j) => DownloadTask(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Video',
        platform: VideoPlatform.values.asNameMap()[j['platform']] ??
            VideoPlatform.other,
        qualityLabel: j['quality'] as String? ?? '',
        status: DownloadStatus.values.asNameMap()[j['status']] ??
            DownloadStatus.failed,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int? ?? 0),
        thumbnailUrl: j['thumb'] as String?,
        received: j['received'] as int? ?? 0,
        total: j['total'] as int?,
        error: j['error'] as String?,
      );
}
