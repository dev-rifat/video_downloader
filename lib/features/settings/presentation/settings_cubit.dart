import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/server_settings.dart';

class SettingsCubit extends Cubit<ServerSettings> {
  SettingsCubit(GetSettings get, this._save) : super(get());
  final SaveSettings _save;

  /// Returns an error message, or null on success.
  Future<String?> save(ServerSettings s) async {
    final r = await _save(s);
    return r.fold((f) => f.message, (v) {
      emit(v);
      return null;
    });
  }
}
