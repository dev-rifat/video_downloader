import 'package:equatable/equatable.dart';

/// Domain-level failure. Presentation only ever sees these.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class InvalidLinkFailure extends Failure {
  const InvalidLinkFailure([super.message = 'Please enter a valid video link.']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

final class ExtractionFailure extends Failure {
  const ExtractionFailure([
    super.message = 'Could not find a downloadable video at this link.',
  ]);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Gallery permission denied. Allow it in Settings.',
  ]);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not save the video.']);
}
