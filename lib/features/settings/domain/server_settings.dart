import 'package:equatable/equatable.dart';

import '../../../core/usecase/result.dart';

/// Optional "universal" extraction server (cobalt-compatible API).
/// Enables Instagram, TikTok, X, and HD YouTube/Facebook.
class ServerSettings extends Equatable {
  const ServerSettings({this.endpoint = '', this.apiKey = ''});
  final String endpoint;
  final String apiKey;

  bool get isConfigured => endpoint.trim().isNotEmpty;

  @override
  List<Object?> get props => [endpoint, apiKey];
}

abstract interface class SettingsRepository {
  ServerSettings get current;
  Future<Result<ServerSettings>> save(ServerSettings settings);
}

class GetSettings {
  const GetSettings(this._repo);
  final SettingsRepository _repo;
  ServerSettings call() => _repo.current;
}

class SaveSettings {
  const SaveSettings(this._repo);
  final SettingsRepository _repo;
  Future<Result<ServerSettings>> call(ServerSettings s) => _repo.save(s);
}
