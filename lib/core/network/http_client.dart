import 'package:dio/dio.dart';

/// Shared, single Dio instance (one connection pool for the whole app).
class HttpClientFactory {
  static const desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

  static Dio create() => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
          maxRedirects: 8,
          headers: {
            'User-Agent': desktopUserAgent,
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );
}
