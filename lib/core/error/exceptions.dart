/// Data-layer exceptions. Converted to [Failure]s inside repositories.
class ExtractionException implements Exception {
  const ExtractionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DownloadCanceledException implements Exception {
  const DownloadCanceledException();
}
