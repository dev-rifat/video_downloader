import 'dart:convert';

/// Lightweight regex helpers (no HTML parser dependency = smaller app).
abstract final class HtmlUtils {
  static String? meta(String html, String property) {
    final p = RegExp.escape(property);
    final a = RegExp(
      '<meta[^>]+(?:property|name)=["\']$p["\'][^>]*content=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(html);
    final b = a ??
        RegExp(
          '<meta[^>]+content=["\']([^"\']+)["\'][^>]*(?:property|name)=["\']$p["\']',
          caseSensitive: false,
        ).firstMatch(html);
    final v = b?.group(1);
    return v == null ? null : decodeEntities(v);
  }

  static String? title(String html) {
    final t = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
        .firstMatch(html)
        ?.group(1);
    return t == null ? null : decodeEntities(t.trim());
  }

  /// Decodes a JSON-escaped string fragment (e.g. `https:\/\/...%`).
  static String unescapeJson(String raw) {
    try {
      return jsonDecode('"$raw"') as String;
    } catch (_) {
      return raw.replaceAll(r'\/', '/');
    }
  }

  static String decodeEntities(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAllMapped(RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)))
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
}
