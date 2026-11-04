import '../../../../core/error/failures.dart';
import '../../../../core/usecase/result.dart';
import '../../../../core/utils/link_utils.dart';
import '../entities/video_info.dart';
import '../repositories/video_repository.dart';

class AnalyzeLink {
  const AnalyzeLink(this._repo);
  final VideoRepository _repo;

  Future<Result<VideoInfo>> call(String input) async {
    final url = LinkUtils.extractUrl(input);
    if (url == null || Uri.tryParse(url)?.hasAuthority != true) {
      return const Error(InvalidLinkFailure());
    }
    return _repo.analyze(url);
  }
}
