import '../entities/download_task.dart';
import '../entities/video_format.dart';
import '../entities/video_info.dart';
import '../repositories/download_repository.dart';

class StartDownload {
  const StartDownload(this._repo);
  final DownloadRepository _repo;
  DownloadTask call(VideoInfo info, VideoFormat format) =>
      _repo.start(info, format);
}

class CancelDownload {
  const CancelDownload(this._repo);
  final DownloadRepository _repo;
  Future<void> call(String id) => _repo.cancel(id);
}

class RemoveDownload {
  const RemoveDownload(this._repo);
  final DownloadRepository _repo;
  Future<void> call(String id) => _repo.remove(id);
}

class WatchDownloads {
  const WatchDownloads(this._repo);
  final DownloadRepository _repo;
  Stream<DownloadTask> call() => _repo.updates;
}

class GetDownloadHistory {
  const GetDownloadHistory(this._repo);
  final DownloadRepository _repo;
  Future<List<DownloadTask>> call() => _repo.history();
}

class OpenGallery {
  const OpenGallery(this._repo);
  final DownloadRepository _repo;
  Future<void> call() => _repo.openGallery();
}
