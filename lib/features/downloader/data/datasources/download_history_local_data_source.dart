import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/download_task.dart';
import '../models/download_task_model.dart';

class DownloadHistoryLocalDataSource {
  DownloadHistoryLocalDataSource(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'download_history_v1';
  static const maxEntries = 60;

  List<DownloadTask> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => DownloadTaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  


  Future<void> save(Iterable<DownloadTask> tasks) {
    final list = tasks.take(maxEntries).map((t) => t.toJson()).toList();
    return _prefs.setString(_key, jsonEncode(list));
  }
}
