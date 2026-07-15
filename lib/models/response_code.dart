/// HTTP response status codes
class ResponseCode {
  /// API status codes
  // success with data
  static const int success = 200;
  // success with no content
  static const int created = 201;
  // accepted for asynchronous processing
  static const int accepted = 202;
  // success with no response body
  static const int noContent = 204;
  // failure, api rejected the request
  static const int badRequest = 400;
  // failure, user is not authorized
  static const int unauthorized = 401;
  // failure, api rejected the request
  static const int forbidden = 403;
  // failure, api url is not correct and not found
  static const int notFound = 404;
  // failure, HTTP method is not supported
  static const int methodNotAllowed = 405;
  // failure, resource state conflicts with the request
  static const int conflict = 409;
  // failure, request rate limit was exceeded
  static const int tooManyRequests = 429;
  // failure, crash happened in server side
  static const int internalServerError = 500;
  // failure authentication required
  static const int networkAuthenticationRequired = 511;
  static const int badCertificate = 495;

  /// local status code
  static const int defaultError = -1;
  static const int connectTimeout = -2;
  static const int cancel = -3;
  static const int receiveTimeout = -4;
  static const int sendTimeout = -5;
  static const int cacheError = -6;
  static const int noInternetConnection = -7;

  /// Whether [statusCode] is in the HTTP success range.
  static bool isSuccessful(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;
}
