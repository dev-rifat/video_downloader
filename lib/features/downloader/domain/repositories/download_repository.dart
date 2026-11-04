import '../entities/download_task.dart';
import '../entities/video_format.dart';
import '../entities/video_info.dart';

abstract interface class DownloadRepository {
  /// Live progress/status updates for every task.
  Stream<DownloadTask> get updates;

  Future<List<DownloadTask>> history();

  /// Queues a download and returns the created task immediately.
  DownloadTask start(VideoInfo info, VideoFormat format);

  Future<void> cancel(String taskId);

  Future<void> remove(String taskId);

  Future<void> openGallery();
}
