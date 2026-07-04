import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:dio/dio.dart';

/// Token pair model for access and refresh tokens
class TokenPair {
  const TokenPair({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
}

/// Exception thrown when the token is revoked or invalid
class RevokeTokenException extends DioException {
  RevokeTokenException({required super.requestOptions});
}

/// JWT Interceptor for handling authentication tokens
///
/// Supports both IStorageService from core_package and callback functions
class JwtInterceptor extends QueuedInterceptor {
  /// Creates a JWT Interceptor
  ///
  /// Either [storageService] or [tokenGetter] must be provided
  /// [refreshTokenEndpoint] - Endpoint for refreshing tokens
  /// [refreshTokenCallback] - Callback function for refreshing tokens
  /// [shouldClearBeforeReset] - Clear tokens before resetting (default: true)
  /// [headerKey] - Header key for authorization (default: 'Authorization')
  /// [tokenPrefix] - Prefix for token in header (default: 'Bearer')
  JwtInterceptor({
    IStorageService? storageService,
    String? Function()? tokenGetter,
    this.refreshTokenEndpoint,
    this.refreshTokenCallback,
    this.shouldClearBeforeReset = true,
    this.headerKey = 'Authorization',
    this.tokenPrefix = 'Bearer',
    required Dio dio,
  }) : _storageService = storageService,
       _tokenGetter = tokenGetter {
    assert(storageService != null || tokenGetter != null, 'Either storageService or tokenGetter must be provided');

    // Initialize clients for refreshing tokens and retrying requests
    _refreshClient = Dio();
    _refreshClient.options = BaseOptions(baseUrl: dio.options.baseUrl);

    _retryClient = Dio();
    _retryClient.options = BaseOptions(baseUrl: dio.options.baseUrl);
  }

  final IStorageService? _storageService;
  final String? Function()? _tokenGetter;
  final bool shouldClearBeforeReset;
  final String headerKey;
  final String tokenPrefix;
  final String? refreshTokenEndpoint;
  final Future<TokenPair?> Function(String refreshToken)? refreshTokenCallback;

  late final Dio _refreshClient;
  late final Dio _retryClient;

  // Keys for token storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _getAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers[headerKey] = '$tokenPrefix $token';
        return handler.next(options);
      }

      // If no token, continue without authentication
      return handler.next(options);
    } catch (e) {
      return handler.reject(RevokeTokenException(requestOptions: options), true);
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // If the error is due to token revocation, handle session expiration logic
    if (err is RevokeTokenException) {
      return handler.reject(err);
    }

    // Check if the response indicates a need to refresh the token
    if (!_shouldRefresh(err.response)) {
      return handler.next(err);
    }

    try {
      final tokenPair = await _getTokenPair();

      // If no token pair is available, reject the error
      if (tokenPair == null) {
        return handler.reject(err);
      }

      // Check if access token is valid
      final isAccessValid = await _isAccessTokenValid();

      if (isAccessValid) {
        // If access token is still valid, retry the previous request
        final previousRequest = await _retry(err.requestOptions);
        return handler.resolve(previousRequest);
      } else {
        // If the access token is invalid, refresh it and retry the request
        final newTokenPair = await _refreshToken(options: err.requestOptions, tokenPair: tokenPair);

        if (newTokenPair == null) {
          return handler.reject(RevokeTokenException(requestOptions: err.requestOptions));
        }

        final previousRequest = await _retry(err.requestOptions);
        return handler.resolve(previousRequest);
      }
    } on RevokeTokenException {
      // Handle session expiration logic in case of revocation
      return handler.reject(err);
    } on DioException catch (e) {
      // If another Dio exception occurs, pass it along
      return handler.next(e);
    }
  }

  /// Get access token from storage or callback
  Future<String?> _getAccessToken() async {
    if (_tokenGetter != null) {
      return _tokenGetter();
    }

    if (_storageService != null) {
      final token = await _storageService.get(_accessTokenKey);
      return token?.toString();
    }

    return null;
  }

  /// Get token pair from storage
  Future<TokenPair?> _getTokenPair() async {
    if (_storageService == null) {
      return null;
    }

    final accessToken = await _storageService.get(_accessTokenKey);
    final refreshToken = await _storageService.get(_refreshTokenKey);

    if (accessToken == null) {
      return null;
    }

    return TokenPair(accessToken: accessToken.toString(), refreshToken: refreshToken?.toString());
  }

  /// Check if access token is valid (can be overridden)
  Future<bool> _isAccessTokenValid() async {
    // Default implementation: always return true
    // Users can override this by providing a custom callback
    return true;
  }

  /// Check if the token pair should be refreshed based on the response
  bool _shouldRefresh(Response? response) => response?.statusCode == 401;

  /// Build headers for the request including the access token
  Future<Map<String, dynamic>> _buildHeaders() async {
    final token = await _getAccessToken();
    if (token == null) {
      return {};
    }
    return {headerKey: '$tokenPrefix $token'};
  }

  /// Refresh the access and refresh tokens
  Future<TokenPair?> _refreshToken({required RequestOptions options, TokenPair? tokenPair}) async {
    if (tokenPair == null || tokenPair.refreshToken == null) {
      throw RevokeTokenException(requestOptions: options);
    }

    try {
      TokenPair? newTokenPair;

      // Use callback if provided
      if (refreshTokenCallback != null) {
        newTokenPair = await refreshTokenCallback!(tokenPair.refreshToken!);
      } else if (refreshTokenEndpoint != null) {
        // Use default refresh endpoint
        _refreshClient.options = _refreshClient.options.copyWith(headers: {'refresh-Token': tokenPair.refreshToken});

        final response = await _refreshClient.post(refreshTokenEndpoint!);

        newTokenPair = TokenPair(
          accessToken: response.data['accessToken'] ?? response.data['access_token'],
          refreshToken: response.data['refreshToken'] ?? response.data['refresh_token'],
        );
      } else {
        throw RevokeTokenException(requestOptions: options);
      }

      if (newTokenPair == null) {
        throw RevokeTokenException(requestOptions: options);
      }

      // Save new tokens
      if (_storageService != null) {
        // Clear old tokens if needed before saving the new ones
        if (shouldClearBeforeReset) {
          await _storageService.remove(_accessTokenKey);
          await _storageService.remove(_refreshTokenKey);
        }

        await _storageService.set(_accessTokenKey, newTokenPair.accessToken);
        if (newTokenPair.refreshToken != null) {
          await _storageService.set(_refreshTokenKey, newTokenPair.refreshToken!);
        }
      }

      return newTokenPair;
    } catch (_) {
      // Clear tokens on failure
      if (_storageService != null) {
        await _storageService.remove(_accessTokenKey);
        await _storageService.remove(_refreshTokenKey);
      }
      throw RevokeTokenException(requestOptions: options);
    }
  }

  /// Retry the request with the previous options
  Future<Response<R>> _retry<R>(RequestOptions requestOptions) async {
    final headers = await _buildHeaders();
    return _retryClient.request<R>(
      requestOptions.path,
      cancelToken: requestOptions.cancelToken,
      data: requestOptions.data is FormData ? (requestOptions.data as FormData).clone() : requestOptions.data,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: requestOptions.extra,
        headers: {...requestOptions.headers, ...headers},
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
        requestEncoder: requestOptions.requestEncoder,
        responseDecoder: requestOptions.responseDecoder,
        listFormat: requestOptions.listFormat,
      ),
    );
  }
}
