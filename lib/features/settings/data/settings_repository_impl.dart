import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecase/result.dart';
import '../domain/server_settings.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs)
      : _current = ServerSettings(
          endpoint: _prefs.getString(_kEndpoint) ?? '',
          apiKey: _prefs.getString(_kKey) ?? '',
        );

  static const _kEndpoint = 'server_endpoint';
  static const _kKey = 'server_api_key';

  final SharedPreferences _prefs;
  ServerSettings _current;

  @override
  ServerSettings get current => _current;

  @override
  Future<Result<ServerSettings>> save(ServerSettings s) async {
    var endpoint = s.endpoint.trim();
    if (endpoint.isNotEmpty) {
      if (!endpoint.startsWith('http')) endpoint = 'https://$endpoint';
      if (Uri.tryParse(endpoint)?.hasAuthority != true) {
        return const Error(InvalidLinkFailure('Invalid server URL.'));
      }
      if (endpoint.endsWith('/')) {
        endpoint = endpoint.substring(0, endpoint.length - 1);
      }
    }
    final next = ServerSettings(endpoint: endpoint, apiKey: s.apiKey.trim());
    await _prefs.setString(_kEndpoint, next.endpoint);
    await _prefs.setString(_kKey, next.apiKey);
    _current = next;
    return Success(next);
  }
}
