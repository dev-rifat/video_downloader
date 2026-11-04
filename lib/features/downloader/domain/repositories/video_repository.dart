import '../../../../core/usecase/result.dart';
import '../entities/video_info.dart';

abstract interface class VideoRepository {
  /// Resolves title, thumbnail and available resolutions for [url].
  Future<Result<VideoInfo>> analyze(String url);
}
