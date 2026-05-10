/// Custom exception thrown when the server returns a non-200 HTTP status code.
/// Used by [MealApiService._checkResponse] and caught in all screens.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
