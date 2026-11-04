import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/video_format.dart';
import '../../domain/entities/video_info.dart';
import '../../domain/usecases/analyze_link.dart';

// ---------------- Events ----------------
sealed class LinkEvent extends Equatable {
  const LinkEvent();
  @override
  List<Object?> get props => [];
}

final class LinkSubmitted extends LinkEvent {
  const LinkSubmitted(this.input);
  final String input;
  @override
  List<Object?> get props => [input];
}

final class LinkCleared extends LinkEvent {
  const LinkCleared();
}

final class FormatSelected extends LinkEvent {
  const FormatSelected(this.format);
  final VideoFormat format;
  @override
  List<Object?> get props => [format];
}

// ---------------- State ----------------
enum LinkStatus { initial, loading, loaded, failure }

final class LinkState extends Equatable {
  const LinkState({
    this.status = LinkStatus.initial,
    this.input = '',
    this.info,
    this.selected,
    this.error,
  });

  final LinkStatus status;
  final String input;
  final VideoInfo? info;
  final VideoFormat? selected;
  final String? error;

  @override
  List<Object?> get props => [status, input, info, selected, error];
}

// ---------------- Bloc ----------------
class LinkBloc extends Bloc<LinkEvent, LinkState> {
  LinkBloc(this._analyze) : super(const LinkState()) {
    on<LinkSubmitted>(_onSubmitted);
    on<LinkCleared>((_, emit) {
      _request++;
      emit(const LinkState());
    });
    on<FormatSelected>((e, emit) => emit(LinkState(
          status: state.status,
          input: state.input,
          info: state.info,
          selected: e.format,
        )));
  }

  final AnalyzeLink _analyze;
  int _request = 0; // newer submissions supersede older ones

  Future<void> _onSubmitted(LinkSubmitted e, Emitter<LinkState> emit) async {
    final input = e.input.trim();
    if (input.isEmpty) return;
    if (state.status == LinkStatus.loading && state.input == input) return;

    final req = ++_request;
    emit(LinkState(status: LinkStatus.loading, input: input));
    final result = await _analyze(input);
    if (req != _request) return; // stale

    emit(result.fold(
      (f) => LinkState(
          status: LinkStatus.failure, input: input, error: f.message),
      (info) => LinkState(
        status: LinkStatus.loaded,
        input: input,
        info: info,
        selected: info.formats.first,
      ),
    ));
  }
}
