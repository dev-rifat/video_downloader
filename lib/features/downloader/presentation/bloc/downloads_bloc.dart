import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/download_task.dart';
import '../../domain/entities/video_format.dart';
import '../../domain/entities/video_info.dart';
import '../../domain/usecases/download_usecases.dart';

// ---------------- Events ----------------
sealed class DownloadsEvent {
  const DownloadsEvent();
}

final class DownloadsStarted extends DownloadsEvent {
  const DownloadsStarted();
}

final class DownloadRequested extends DownloadsEvent {
  const DownloadRequested(this.info, this.format);
  final VideoInfo info;
  final VideoFormat format;
}

final class DownloadCanceled extends DownloadsEvent {
  const DownloadCanceled(this.id);
  final String id;
}

final class DownloadRemoved extends DownloadsEvent {
  const DownloadRemoved(this.id);
  final String id;
}

final class GalleryOpened extends DownloadsEvent {
  const GalleryOpened();
}

final class _TaskUpdated extends DownloadsEvent {
  const _TaskUpdated(this.task);
  final DownloadTask task;
}

// ---------------- State ----------------
/// [ids] keeps its identity unless items are added/removed, so the list
/// view only rebuilds on structural changes; each tile selects its own
/// task from [byId] and rebuilds alone on progress ticks.
final class DownloadsState extends Equatable {
  const DownloadsState({this.ids = const [], this.byId = const {}});
  final List<String> ids;
  final Map<String, DownloadTask> byId;

  int get activeCount => byId.values.where((t) => t.status.isActive).length;

  @override
  List<Object?> get props => [identityHashCode(ids), byId];
}

// ---------------- Bloc ----------------
class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  DownloadsBloc({
    required WatchDownloads watch,
    required GetDownloadHistory history,
    required StartDownload start,
    required CancelDownload cancel,
    required RemoveDownload remove,
    required OpenGallery openGallery,
  })  : _watch = watch,
        _history = history,
        _start = start,
        _cancel = cancel,
        _remove = remove,
        _openGallery = openGallery,
        super(const DownloadsState()) {
    on<DownloadsStarted>(_onStarted);
    on<_TaskUpdated>(_onUpdated);
    on<DownloadRequested>((e, _) => _start(e.info, e.format));
    on<DownloadCanceled>((e, _) => _cancel(e.id));
    on<DownloadRemoved>(_onRemoved);
    on<GalleryOpened>((_, _) => _openGallery());
  }

  final WatchDownloads _watch;
  final GetDownloadHistory _history;
  final StartDownload _start;
  final CancelDownload _cancel;
  final RemoveDownload _remove;
  final OpenGallery _openGallery;
  StreamSubscription<DownloadTask>? _sub;

  Future<void> _onStarted(DownloadsStarted e, Emitter<DownloadsState> emit) async {
    _sub ??= _watch().listen((t) => add(_TaskUpdated(t)));
    final tasks = await _history();
    final byId = {...state.byId, for (final t in tasks) t.id: t};
    final ids = [
      ...state.ids,
      ...tasks.map((t) => t.id).where((id) => !state.byId.containsKey(id)),
    ];
    emit(DownloadsState(ids: ids, byId: byId));
  }

  void _onUpdated(_TaskUpdated e, Emitter<DownloadsState> emit) {
    final t = e.task;
    final isNew = !state.byId.containsKey(t.id);
    emit(DownloadsState(
      ids: isNew ? [t.id, ...state.ids] : state.ids,
      byId: {...state.byId, t.id: t},
    ));
  }

  Future<void> _onRemoved(DownloadRemoved e, Emitter<DownloadsState> emit) async {
    emit(DownloadsState(
      ids: state.ids.where((id) => id != e.id).toList(),
      byId: Map.of(state.byId)..remove(e.id),
    ));
    await _remove(e.id);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
