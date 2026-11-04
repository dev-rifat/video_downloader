abstract final class Formatters {
  static String bytes(int? b) {
    if (b == null || b <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    var v = b.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(i >= 2 ? 1 : 0)} ${units[i]}';
  }

  static String duration(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String safeFileName(String input, {int max = 60}) {
    final cleaned = input
        .replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final name = cleaned.isEmpty ? 'video' : cleaned;
    return name.length > max ? name.substring(0, max).trim() : name;
  }
}
