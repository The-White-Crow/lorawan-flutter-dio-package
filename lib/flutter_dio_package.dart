/// Dio Package - A reusable Flutter package for HTTP requests using Dio
///
/// This package provides:
/// - Dio client configuration with DioBuilder
/// - Interceptors for logging, authentication (JWT), and error handling
/// - Safe call extensions with Either<Failure, T>
/// - Response models and error handling
/// - Request/Response interceptors
library dio_package;

// Core exports
export 'core/dio_builder.dart';
export 'core/request_type.dart';

// Extensions exports
export 'extensions/safe_call_extensions.dart';

// Interceptors exports
export 'interceptors/logging_interceptor.dart';
export 'interceptors/jwt_interceptor.dart';
export 'interceptors/error_interceptor.dart';

// Models exports
export 'models/api_response.dart';
export 'models/api_error.dart';
export 'models/response_code.dart';

// Handlers exports
export 'handlers/error_handler.dart';
