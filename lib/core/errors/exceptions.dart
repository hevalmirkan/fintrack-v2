class UnauthenticatedException implements Exception {
  final String message;
  const UnauthenticatedException([this.message = 'User is not authenticated']);
  @override
  String toString() => 'UnauthenticatedException: $message';
}

class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;
  const RepositoryException(this.message, [this.originalError]);
  @override
  String toString() =>
      'RepositoryException: $message ${originalError != null ? "($originalError)" : ""}';
}
