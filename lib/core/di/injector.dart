import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/downloader/data/datasources/download_history_local_data_source.dart';
import '../../features/downloader/data/datasources/extractors/cobalt_extractor.dart';
import '../../features/downloader/data/datasources/extractors/facebook_extractor.dart';
import '../../features/downloader/data/datasources/extractors/generic_extractor.dart';
import '../../features/downloader/data/datasources/extractors/youtube_extractor.dart';
import '../../features/downloader/data/datasources/file_downloader.dart';
import '../../features/downloader/data/datasources/gallery_data_source.dart';
import '../../features/downloader/data/repositories/download_repository_impl.dart';
import '../../features/downloader/data/repositories/video_repository_impl.dart';
import '../../features/downloader/domain/repositories/download_repository.dart';
import '../../features/downloader/domain/repositories/video_repository.dart';
import '../../features/downloader/domain/usecases/analyze_link.dart';
import '../../features/downloader/domain/usecases/download_usecases.dart';
import '../../features/downloader/presentation/bloc/downloads_bloc.dart';
import '../../features/downloader/presentation/bloc/link_bloc.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/server_settings.dart';
import '../../features/settings/presentation/settings_cubit.dart';
import '../network/http_client.dart';
import '../platform/share_intent_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final dio = HttpClientFactory.create();

  // Core
  sl
    ..registerSingleton(prefs)
    ..registerSingleton(dio)
    ..registerLazySingleton(ShareIntentService.new);

  // Settings
  sl
    ..registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(sl()))
    ..registerFactory(() => GetSettings(sl()))
    ..registerFactory(() => SaveSettings(sl()))
    ..registerFactory(() => SettingsCubit(sl(), sl()));

  // Data sources — extractors are lazy so YouTube's client is only
  // created when first needed.
  sl
    ..registerLazySingleton(YoutubeExtractor.new)
    ..registerLazySingleton(() => FacebookExtractor(sl()))
    ..registerLazySingleton(() => CobaltExtractor(sl(), sl()))
    ..registerLazySingleton(() => GenericExtractor(sl()))
    ..registerLazySingleton(() => FileDownloader(sl()))
    ..registerLazySingleton(GalleryDataSource.new)
    ..registerLazySingleton(() => DownloadHistoryLocalDataSource(sl()));

  // Repositories
  sl
    ..registerLazySingleton(() => VideoRepositoryImpl(
          // Priority order: universal server (if configured, gives HD),
          // native on-device extractors, then generic web fallback.
          [
            sl<CobaltExtractor>(),
            sl<YoutubeExtractor>(),
            sl<FacebookExtractor>(),
            sl<GenericExtractor>(),
          ],
        ))
    ..registerLazySingleton<VideoRepository>(() => sl<VideoRepositoryImpl>())
    ..registerLazySingleton<DownloadRepository>(() => DownloadRepositoryImpl(
          videos: sl(),
          downloader: sl(),
          gallery: sl(),
          local: sl(),
        ));

  // Use cases
  sl
    ..registerFactory(() => AnalyzeLink(sl()))
    ..registerFactory(() => StartDownload(sl()))
    ..registerFactory(() => CancelDownload(sl()))
    ..registerFactory(() => RemoveDownload(sl()))
    ..registerFactory(() => WatchDownloads(sl()))
    ..registerFactory(() => GetDownloadHistory(sl()))
    ..registerFactory(() => OpenGallery(sl()));

  // Blocs
  sl
    ..registerFactory(() => LinkBloc(sl()))
    ..registerFactory(() => DownloadsBloc(
          watch: sl(),
          history: sl(),
          start: sl(),
          cancel: sl(),
          remove: sl(),
          openGallery: sl(),
        ));
}
