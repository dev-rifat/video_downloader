import 'package:downloader/core/error/failures.dart';
import 'package:downloader/core/usecase/result.dart';
import 'package:downloader/features/downloader/domain/entities/video_format.dart';
import 'package:downloader/features/downloader/domain/entities/video_info.dart';
import 'package:downloader/features/downloader/domain/entities/video_platform.dart';
import 'package:downloader/features/downloader/domain/repositories/video_repository.dart';
import 'package:downloader/features/downloader/domain/usecases/analyze_link.dart';
import 'package:downloader/features/downloader/presentation/bloc/link_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements VideoRepository {
  @override
  Future<Result<VideoInfo>> analyze(String url) async {
    if (url.contains('bad')) return const Error(ExtractionFailure('nope'));
    return Success(VideoInfo(
      sourceUrl: url,
      title: 'Clip',
      platform: VideoPlatform.facebook,
      extractorId: 'facebook',
      formats: const [
        VideoFormat(id: 'hd', label: 'HD', height: 720),
        VideoFormat(id: 'sd', label: 'SD', height: 360),
      ],
    ));
  }
}

void main() {
  late LinkBloc bloc;
  setUp(() => bloc = LinkBloc(AnalyzeLink(_FakeRepo())));
  tearDown(() => bloc.close());

  test('shared text → loaded with best format preselected', () async {
    bloc.add(const LinkSubmitted('Watch https://fb.watch/ok'));
    await expectLater(
      bloc.stream.map((s) => s.status),
      emitsInOrder([LinkStatus.loading, LinkStatus.loaded]),
    );
    expect(bloc.state.selected?.label, 'HD');
    bloc.add(FormatSelected(bloc.state.info!.formats.last));
    await bloc.stream.first;
    expect(bloc.state.selected?.label, 'SD');
  });

  test('invalid input → failure', () async {
    bloc.add(const LinkSubmitted('hello'));
    await expectLater(bloc.stream.map((s) => s.status),
        emitsInOrder([LinkStatus.loading, LinkStatus.failure]));
  });

  test('extractor error message surfaces', () async {
    bloc.add(const LinkSubmitted('https://bad.com/x'));
    await bloc.stream.firstWhere((s) => s.status == LinkStatus.failure);
    expect(bloc.state.error, 'nope');
  });
}
